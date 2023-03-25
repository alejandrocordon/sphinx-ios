// AllTribeFeedsCollectionViewController.swift
//
// Created by CypherPoet.
// ✌️
//
    
import UIKit
import CoreData


class AllTribeFeedsCollectionViewController: UICollectionViewController {
    var followedFeeds: [ContentFeed] = []
    
    var recommendedFeeds: [RecommendationResult] = []
    
    var interSectionSpacing: CGFloat = 10.0
    var interCellSpacing: CGFloat = 6.0

    var onCellSelected: ((NSManagedObjectID) -> Void)!
    var onRecommendationSelected: (([RecommendationResult], String) -> Void)!
    var onContentScrolled: ((UIScrollView) -> Void)?
    var onNewResultsFetched: ((Int) -> Void)!

    private var managedObjectContext: NSManagedObjectContext!
    private var fetchedResultsController: NSFetchedResultsController<ContentFeed>!
    private var currentDataSnapshot: DataSourceSnapshot!
    private var dataSource: DataSource!
    
    private var recommendationsHelper = RecommendationsHelper.sharedInstance

    private let itemContentInsets = NSDirectionalEdgeInsets(
        top: 0,
        leading: 12,
        bottom: 0,
        trailing: 0
    )
    
    override var collectionViewLayout: UICollectionViewLayout {

        let layout = UICollectionViewCompositionalLayout { [weak self] (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in

            let section = CollectionViewSection(rawValue: sectionIndex)
            let firstDataSourceItem = self?.dataSource.itemIdentifier(for: IndexPath(row: 0, section: sectionIndex))

            switch section {
            case .recommendations:
                if (
                    firstDataSourceItem?.isLoading == true ||
                    firstDataSourceItem?.noResults == true
                ) {
                    return self?.makeEmptySectionLayout()
                }
                return self?.makeFeedsItemSectionLayout()
            default:
                return self?.makeFeedsItemSectionLayout()
            }
        }
        
        let layoutConfiguration = UICollectionViewCompositionalLayoutConfiguration()
        layoutConfiguration.interSectionSpacing = interSectionSpacing
        
        layout.configuration = layoutConfiguration

        return layout
    }
}


// MARK: - Instantiation
extension AllTribeFeedsCollectionViewController {

    static func instantiate(
        managedObjectContext: NSManagedObjectContext = CoreDataManager.sharedManager.persistentContainer.viewContext,
        interSectionSpacing: CGFloat = 10.0,
        onCellSelected: ((NSManagedObjectID) -> Void)!,
        onRecommendationSelected: (([RecommendationResult], String) -> Void)!,
        onNewResultsFetched: @escaping ((Int) -> Void) = { _ in },
        onContentScrolled: ((UIScrollView) -> Void)? = nil
    ) -> AllTribeFeedsCollectionViewController {
        let viewController = StoryboardScene
            .Dashboard
            .allTribeFeedsCollectionViewController
            .instantiate()

        viewController.managedObjectContext = managedObjectContext

        viewController.interSectionSpacing = interSectionSpacing
        viewController.onCellSelected = onCellSelected
        viewController.onRecommendationSelected = onRecommendationSelected
        viewController.onNewResultsFetched = onNewResultsFetched
        viewController.onContentScrolled = onContentScrolled
        
        viewController.fetchedResultsController = Self.makeFetchedResultsController(using: managedObjectContext)
        viewController.fetchedResultsController.delegate = viewController
        
        return viewController
    }
}


// MARK: - Layout & Data Structure
extension AllTribeFeedsCollectionViewController {
    
    enum CollectionViewSection: Int, CaseIterable {
        case recommendations
        case followedFeeds
        case recentlyPlayed
        
        var titleForDisplay: String {
            switch self {
                case .recommendations:
                    return "feed.recommendations".localized
                case .followedFeeds:
                    return "feed.following".localized
                case .recentlyPlayed:
                    return "Recently Played"
            }
        }
    }
    
    
    enum DataSourceItem: Hashable {
        
        case tribePodcastFeed(ContentFeed, Int)
        case tribeVideoFeed(ContentFeed, Int)
        case tribeNewsletterFeed(ContentFeed, Int)
        
        case recommendedFeed(RecommendationResult)
        
        case loading
        case noResults
        
        static func hasEqualValues(_ lhs: DataSourceItem, _ rhs: DataSourceItem) -> Bool {
            if let lhsContentFeed = lhs.feedEntity as? ContentFeed,
               let rhsContentFeed = rhs.feedEntity as? ContentFeed {
                
                return
                    lhs.sectionEntity == rhs.sectionEntity &&
                    lhsContentFeed.feedID == rhsContentFeed.feedID &&
                    lhsContentFeed.title == rhsContentFeed.title &&
                    lhsContentFeed.feedURL?.absoluteString == rhsContentFeed.feedURL?.absoluteString &&
                    lhsContentFeed.items?.count ?? 0 == rhsContentFeed.items?.count ?? 0 &&
                    lhsContentFeed.itemsArray.last?.datePublished == rhsContentFeed.itemsArray.last?.datePublished &&
                    lhsContentFeed.itemsArray.first?.id == rhsContentFeed.itemsArray.first?.id &&
                    lhsContentFeed.itemsArray.first?.datePublished == rhsContentFeed.itemsArray.first?.datePublished
//                    lhsContentFeed.getLastEpisode()?.publishDate == rhsContentFeed.getLastEpisode()?.publishDate
            }
            if let lhsContentFeed = lhs.resultEntity,
               let rhsContentFeed = rhs.resultEntity {
                
                return
                    lhsContentFeed.uuid == rhsContentFeed.uuid &&
                    lhsContentFeed.id == rhsContentFeed.id &&
                    lhsContentFeed.link == rhsContentFeed.link
            }
            return false
        }

        static func == (lhs: DataSourceItem, rhs: DataSourceItem) -> Bool {
            switch (lhs, rhs) {
            case ( .tribePodcastFeed(_, _), .tribePodcastFeed(_, _)):
                return DataSourceItem.hasEqualValues(lhs, rhs)
            case ( .tribeVideoFeed(_, _), .tribeVideoFeed(_, _)):
                return DataSourceItem.hasEqualValues(lhs, rhs)
            case ( .tribeNewsletterFeed(_, _), .tribeNewsletterFeed(_, _)):
                return DataSourceItem.hasEqualValues(lhs, rhs)
            case ( .recommendedFeed(_), .recommendedFeed(_)):
                return DataSourceItem.hasEqualValues(lhs, rhs)
            default:
                return false
            }
        }

        func hash(into hasher: inout Hasher) {
            if let contentFeed = self.feedEntity as? ContentFeed {
                hasher.combine(contentFeed.feedID)
            }
            if let recommendation = self.resultEntity {
                hasher.combine(recommendation.uuid)
            }
        }
        
    }

    
    typealias ReusableHeaderView = DashboardFeedCollectionViewSectionHeader
    typealias CellDataItem = DataSourceItem
    typealias DataSource = UICollectionViewDiffableDataSource<CollectionViewSection, CellDataItem>
    typealias DataSourceSnapshot = NSDiffableDataSourceSnapshot<CollectionViewSection, CellDataItem>
}


// MARK: - Lifecycle
extension AllTribeFeedsCollectionViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        registerViews(for: collectionView)
        configure(collectionView)
        configureDataSource(for: collectionView)
        addTableBottomInset(for: collectionView)
        
        fetchItems()
        loadRecommendations()
    }
    
    func addTableBottomInset(for collectionView: UICollectionView) {
        let windowInsets = getWindowInsets()
        let bottomBarHeight:CGFloat = 64
        
        collectionView.contentInset.bottom = bottomBarHeight + windowInsets.bottom
        collectionView.verticalScrollIndicatorInsets.bottom = bottomBarHeight + windowInsets.bottom
    }
}


// MARK: - Layout Composition
extension AllTribeFeedsCollectionViewController {

    func makeSectionHeader() -> NSCollectionLayoutBoundarySupplementaryItem {
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(80)
        )

        return NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
    }
    
    func makeFeedsItemSectionLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = itemContentInsets

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(160.0),
            heightDimension: .absolute(255.0)
        )
        
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)

        section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
        section.boundarySupplementaryItems = [makeSectionHeader()]
        section.contentInsets = .init(top: 11, leading: 0, bottom: 11, trailing: 12)

        return section
    }
    
    func makeEmptySectionLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = itemContentInsets

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(255.0)
        )
        
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)

        section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
        section.boundarySupplementaryItems = [makeSectionHeader()]
        section.contentInsets = .init(top: 11, leading: 0, bottom: 11, trailing: 12)

        return section
    }
}


// MARK: - Collection View Configuration and View Registration
extension AllTribeFeedsCollectionViewController {

    func registerViews(for collectionView: UICollectionView) {
        collectionView.register(
            DashboardFeedSquaredThumbnailCollectionViewCell.nib,
            forCellWithReuseIdentifier: DashboardFeedSquaredThumbnailCollectionViewCell.reuseID
        )
        
        collectionView.register(
            LoadingRecommendationsCollectionViewCell.nib,
            forCellWithReuseIdentifier: LoadingRecommendationsCollectionViewCell.reuseID
        )
        
        collectionView.register(
            NoRecommendationsCollectionViewCell.nib,
            forCellWithReuseIdentifier: NoRecommendationsCollectionViewCell.reuseID
        )
        
        collectionView.register(
            ReusableHeaderView.nib,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: ReusableHeaderView.reuseID
        )
    }


    func configure(_ collectionView: UICollectionView) {        
        collectionView.collectionViewLayout = self.collectionViewLayout
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = .Sphinx.ListBG
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInset = .init(top: 20, left: 0, bottom: 0, right: 0)
        
        collectionView.delegate = self
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        onContentScrolled?(scrollView)
    }
}


// MARK: - Data Source Configuration
extension AllTribeFeedsCollectionViewController {

    func makeDataSource(for collectionView: UICollectionView) -> DataSource {
        let dataSource = DataSource(
            collectionView: collectionView,
            cellProvider: makeCellProvider(for: collectionView)
        )

        dataSource.supplementaryViewProvider = makeSupplementaryViewProvider(for: collectionView)

        return dataSource
    }


    func configureDataSource(for collectionView: UICollectionView) {
        dataSource = makeDataSource(for: collectionView)

        let snapshot = makeSnapshotForCurrentState()

        dataSource.apply(snapshot, animatingDifferences: false)
    }
}


// MARK: - Data Source View Providers
extension AllTribeFeedsCollectionViewController {

    func makeCellProvider(for collectionView: UICollectionView) -> DataSource.CellProvider {
        { (collectionView, indexPath, dataSourceItem) -> UICollectionViewCell in
            guard
                let section = CollectionViewSection(rawValue: indexPath.section)
            else {
                preconditionFailure("Unexpected Section index path")
            }
            
            switch section {
            case .followedFeeds, .recommendations, .recentlyPlayed:
                if dataSourceItem.isLoading {
                    guard
                        let loadingCell = collectionView.dequeueReusableCell(
                            withReuseIdentifier: LoadingRecommendationsCollectionViewCell.reuseID,
                            for: indexPath
                        ) as? LoadingRecommendationsCollectionViewCell
                    else {
                        preconditionFailure("Failed to dequeue expected reusable cell type")
                    }
                    loadingCell.startAnimating()
                    return loadingCell
                } else if dataSourceItem.noResults {
                    guard
                        let noRecommendationsCell = collectionView.dequeueReusableCell(
                            withReuseIdentifier: NoRecommendationsCollectionViewCell.reuseID,
                            for: indexPath
                        ) as? NoRecommendationsCollectionViewCell
                    else {
                        preconditionFailure("Failed to dequeue expected reusable cell type")
                    }
                    return noRecommendationsCell
                }
                
                guard
                    let feedCell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: DashboardFeedSquaredThumbnailCollectionViewCell.reuseID,
                        for: indexPath
                    ) as? DashboardFeedSquaredThumbnailCollectionViewCell
                else {
                    preconditionFailure("Failed to dequeue expected reusable cell type")
                }
                
                if let feedEntity = dataSourceItem.feedEntity as? DashboardFeedSquaredThumbnailCollectionViewItem {
                    feedCell.configure(withItem: feedEntity)
                } else if let resultEntity = dataSourceItem.resultEntity {
                    feedCell.configure(withItem: resultEntity as DashboardFeedSquaredThumbnailCollectionViewItem)
                } else {
                    preconditionFailure("Failed to find entity that conforms to `DashboardFeedSquaredThumbnailCollectionViewItem`")
                }
                
                return feedCell
            }
        }
    }


    func makeSupplementaryViewProvider(for collectionView: UICollectionView) -> DataSource.SupplementaryViewProvider {
        return {
            (collectionView: UICollectionView, kind: String, indexPath: IndexPath)
        -> UICollectionReusableView? in
            switch kind {
            case UICollectionView.elementKindSectionHeader:
                guard let headerView = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: ReusableHeaderView.reuseID,
                    for: indexPath
                ) as? ReusableHeaderView else {
                    preconditionFailure()
                }
                
                var section = CollectionViewSection.allCases[indexPath.section]
                
                if !self.isTrackingEnabled() {
                    if (section == .recommendations){
                        section = .followedFeeds
                    } else if (section == .followedFeeds){
                        section = .recentlyPlayed
                    }
                }
                
                let firstDataSourceItem = self.dataSource.itemIdentifier(for: IndexPath(row: 0, section: 0))
                let isLoadingRecommendations = firstDataSourceItem?.isLoading == true
                
                headerView.render(
                    withTitle: section.titleForDisplay,
                    delegate: self,
                    refreshButton: (section == .recommendations) && !isLoadingRecommendations
                )

                return headerView
            default:
                return UICollectionReusableView()
            }
        }
    }
}


// MARK: - Data Source Snapshot
extension AllTribeFeedsCollectionViewController {

    func isTrackingEnabled() -> Bool{
        return UserDefaults.Keys.shouldTrackActions.get(defaultValue: false)
    }
    
    func makeSnapshotForCurrentState(
        loadingRecommendations: Bool = false
    ) -> DataSourceSnapshot {
        
        var snapshot = DataSourceSnapshot()
        
        if (isTrackingEnabled()) {
            snapshot.appendSections([CollectionViewSection.recommendations])

            if loadingRecommendations {
                snapshot.appendItems(
                    [DataSourceItem.loading],
                    toSection: .recommendations
                )
            } else {

                let recommendedSourceItems = recommendedFeeds.compactMap { recommendations -> DataSourceItem? in
                    return DataSourceItem.recommendedFeed(recommendations)
                }

                if recommendedSourceItems.count > 0 {
                    snapshot.appendItems(
                        recommendedSourceItems,
                        toSection: .recommendations
                    )
                } else {
                    snapshot.appendItems(
                        [DataSourceItem.noResults],
                        toSection: .recommendations
                    )
                }
            }
        }
          
        let followedSourceItems = followedFeeds.sorted { (first, second) in
            let firstDate = first.itemsArray.first?.datePublished ?? Date.init(timeIntervalSince1970: 0)
            let secondDate = second.itemsArray.first?.datePublished ?? Date.init(timeIntervalSince1970: 0)

            return firstDate > secondDate
        }.compactMap { contentFeed -> DataSourceItem? in
            if contentFeed.isPodcast {
                return DataSourceItem.tribePodcastFeed(contentFeed, CollectionViewSection.followedFeeds.rawValue)
            } else if contentFeed.isVideo {
                return DataSourceItem.tribeVideoFeed(contentFeed, CollectionViewSection.followedFeeds.rawValue)
            } else if contentFeed.isNewsletter {
                return DataSourceItem.tribeNewsletterFeed(contentFeed, CollectionViewSection.followedFeeds.rawValue)
            }
            return nil
        }
        
        let recentlyPlayedFeed = followedFeeds.sorted { (first, second) in
            let firstDate = first.dateLastConsumed ?? Date.init(timeIntervalSince1970: 0)
            let secondDate = second.dateLastConsumed ?? Date.init(timeIntervalSince1970: 0)

            return firstDate > secondDate
        }.compactMap { contentFeed -> DataSourceItem? in
            if contentFeed.isPodcast {
                return DataSourceItem.tribePodcastFeed(contentFeed, CollectionViewSection.recentlyPlayed.rawValue)
            } else if contentFeed.isVideo {
                return DataSourceItem.tribeVideoFeed(contentFeed, CollectionViewSection.recentlyPlayed.rawValue)
            } else if contentFeed.isNewsletter {
                return DataSourceItem.tribeNewsletterFeed(contentFeed, CollectionViewSection.recentlyPlayed.rawValue)
            }
            return nil
        }

        if followedSourceItems.count > 0 {
            snapshot.appendSections([CollectionViewSection.followedFeeds, CollectionViewSection.recentlyPlayed])

            snapshot.appendItems(
                followedSourceItems,
                toSection: CollectionViewSection.followedFeeds
            )
            
            snapshot.appendItems(
                recentlyPlayedFeed,
                toSection: CollectionViewSection.recentlyPlayed
            )
        }
        
        currentDataSnapshot = snapshot
        
        return snapshot
    }


    func updateSnapshot() {
        let snapshot = makeSnapshotForCurrentState()

        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    func updateWithNew(
        feeds followedFeeds: [ContentFeed]
    ) {
        self.followedFeeds = followedFeeds
        
        let firstDataSourceItem = self.dataSource.itemIdentifier(for: IndexPath(row: 0, section: 0))
        let isLoadingRecommendations = firstDataSourceItem?.isLoading == true

        if let dataSource = dataSource {
            let snapshot = makeSnapshotForCurrentState(
                loadingRecommendations: isLoadingRecommendations
            )
            
            dataSource.apply(
                snapshot,
                animatingDifferences: false
            )
        }
    }
    
    func updateWithNew(
        recommendations: [RecommendationResult]
    ) {
        self.recommendedFeeds = recommendations.sorted { (first, second) in
            let firstDate = first.publishDate  ?? Date.init(timeIntervalSince1970: 0)
            let secondDate = second.publishDate ?? Date.init(timeIntervalSince1970: 0)
            
            return firstDate > secondDate
        }

        if let dataSource = dataSource {
            
            let snapshot = makeSnapshotForCurrentState()
            
            if #available(iOS 15.0, *), snapshot.numberOfSections > 1 {
                dataSource.applySnapshotUsingReloadData(snapshot, completion: nil)
            } else {
                dataSource.apply(snapshot, animatingDifferences: false, completion: nil)
            }
        }
    }
    
    func updateLoadingRecommendations() {
        self.recommendedFeeds = []

        if let dataSource = dataSource {
            
            let snapshot = makeSnapshotForCurrentState(
                loadingRecommendations: true
            )
            
            if #available(iOS 15.0, *), snapshot.numberOfSections > 1 {
                dataSource.applySnapshotUsingReloadData(snapshot, completion: nil)
            } else {
                dataSource.apply(snapshot, animatingDifferences: false, completion: nil)
            }
        }
    }
    
    func updateNoRecommendationsFound() {
        self.recommendedFeeds = []

        if let dataSource = dataSource {
            
            let snapshot = makeSnapshotForCurrentState(
                loadingRecommendations: false
            )
            
            if #available(iOS 15.0, *), snapshot.numberOfSections > 1 {
                dataSource.applySnapshotUsingReloadData(snapshot, completion: nil)
            } else {
                dataSource.apply(snapshot, animatingDifferences: false, completion: nil)
            }
        }
    }
}


// MARK: -  Fetched Result Controller
extension AllTribeFeedsCollectionViewController {
    
    static func makeFetchedResultsController(
        using managedObjectContext: NSManagedObjectContext
    ) -> NSFetchedResultsController<ContentFeed> {
        let fetchRequest = ContentFeed.FetchRequests.followedFeeds()
        
        return NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
    }
    
    func fetchItems() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            AlertHelper.showAlert(
                title: "Data Loading Error",
                message: "\(error)"
            )
        }
    }
    
    func loadRecommendations() {
        updateLoadingRecommendations()
        
        API.sharedInstance.getFeedRecommendations(callback: { recommendations in
            self.updateWithNew(recommendations: recommendations)
        }, errorCallback: {
            self.updateNoRecommendationsFound()
        })
    }
    
    func scrollBackMostRecentFeed(){
        let mostRecentSectionNumber = (isTrackingEnabled()) ? 2 : 1
        let indexPath = IndexPath(item: 0, section: mostRecentSectionNumber)//todo: programmatically determine the most recent section #
        self.collectionView.scrollToItem(at: indexPath, at: [.centeredVertically, .centeredHorizontally], animated: true)
    }
}


// MARK: - `UICollectionViewDelegate` Methods
extension AllTribeFeedsCollectionViewController {

    override func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard
            let dataSourceItem = dataSource.itemIdentifier(for: indexPath)
        else {
            return
        }

        if let feedEntity = dataSourceItem.feedEntity {
            onCellSelected?(feedEntity.objectID)
            scrollBackMostRecentFeed()
        } else if let recommendation = dataSourceItem.resultEntity {
            onRecommendationSelected?(recommendedFeeds, recommendation.id)
        }
    }
}


extension AllTribeFeedsCollectionViewController: NSFetchedResultsControllerDelegate {
    
    /// Called when the contents of the fetched results controller change.
    ///
    /// If this method is implemented, no other delegate methods will be invoked.
    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference
    ) {
        guard
            let resultController = controller as? NSFetchedResultsController<NSManagedObject>,
            let firstSection = resultController.sections?.first,
            let foundFeeds = firstSection.objects as? [ContentFeed]
        else {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.updateWithNew(
                feeds: foundFeeds
            )
            
            //Sent 1 to always show recommendations
            self?.onNewResultsFetched(1)
        }
    }
}

extension AllTribeFeedsCollectionViewController: DashboardFeedHeaderDelegate {
    func didTapOnRefresh() {
        if (PodcastPlayerController.sharedInstance.isPlayingRecommendations()) {
            AlertHelper.showAlert(title: "Recommendations", message: "You can't get new recommendations while playing them. Please stop playing before refreshing.", on: self)
        } else {
            loadRecommendations()
        }
    }
}


// MARK: -  Computeds
extension AllTribeFeedsCollectionViewController.DataSourceItem {
    
    var feedEntity: NSManagedObject? {
        switch self {
            case .tribePodcastFeed(let podcastFeed, _):
                return podcastFeed
            case .tribeVideoFeed(let videoFeed, _):
                return videoFeed
            case .tribeNewsletterFeed(let newsletterFeed, _):
                return newsletterFeed
            default:
                return nil
        }
    }
    
    var sectionEntity: Int? {
        switch self {
            case .tribePodcastFeed(_, let section):
                return section
            case .tribeVideoFeed(_, let section):
                return section
            case .tribeNewsletterFeed(_, let section):
                return section
            default:
                return nil
        }
    }
    
    var resultEntity: RecommendationResult? {
        switch self {
            case .recommendedFeed(let recommendedFeed):
                return recommendedFeed
            default:
                return nil
        }
    }
    
    var isLoading: Bool {
        switch self {
        case .loading:
            return true
        default:
            return false
        }
    }
    
    var noResults: Bool {
        switch self {
        case .noResults:
            return true
        default:
            return false
        }
    }
}
