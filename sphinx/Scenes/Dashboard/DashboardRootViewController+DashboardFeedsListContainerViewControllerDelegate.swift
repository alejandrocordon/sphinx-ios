import UIKit
import CoreData


extension DashboardRootViewController: DashboardFeedsListContainerViewControllerDelegate, NewsletterFeedContainerViewControllerDelegate {
    
    func viewController(_ viewController: UIViewController, didSelectFeedSearchResult searchResult: FeedSearchResult) {
        let contentFeed: ContentFeed? = CoreDataManager.sharedManager.getObjectWith(objectId: searchResult.objectID)
        
        if let contentFeed = contentFeed {
            if contentFeed.isPodcast {
                let podcastFeed = PodcastFeed.convertFrom(contentFeed: contentFeed)
                self.viewController(self, didSelectPodcastFeed: podcastFeed)
            } else if contentFeed.isVideo {
                self.viewController(self, didSelectVideoFeedWithID: contentFeed.objectID)
            } else if contentFeed.isNewsletter {
                self.viewController(self, didSelectNewsletterFeedWithID: contentFeed.objectID)
            }
        }
    }
    
    func viewController(
        _ viewController: UIViewController,
        didSelectPodcastEpisodeWithID podcastEpisodeID: NSManagedObjectID
    ) {
        guard
            let contentFeedItem = managedObjectContext.object(with: podcastEpisodeID) as? ContentFeedItem,
            contentFeedItem.contentFeed?.isPodcast == true
        else {
            preconditionFailure()
        }
        
        if let contentFeed = contentFeedItem.contentFeed {
            
            let podcastFeed = PodcastFeed.convertFrom(contentFeed:  contentFeed)
            presentPodcastPlayerFor(podcastFeed)
        }
    }
    
    func viewController(
        _ viewController: UIViewController,
        didSelectPodcastFeed podcastFeed: PodcastFeed
    ) {
        guard let _ = podcastFeed.feedURLPath else {
            AlertHelper.showAlert(title: "Failed to find a URL for the feed.", message: "")
            return
        }
        
        presentPodcastPlayerFor(podcastFeed)
    }
    
    func viewController(
        _ viewController: UIViewController,
        didSelectVideoFeedWithID videoFeedID: NSManagedObjectID
    ) {
        guard
            let contentFeed = managedObjectContext.object(with: videoFeedID) as? ContentFeed,
            contentFeed.isVideo
        else {
            preconditionFailure()
        }
        
        let videoFeed = VideoFeed.convertFrom(contentFeed: contentFeed)

        if let latestEpisode = videoFeed.videosArray.first {
            presentVideoPlayer(for: latestEpisode)
        }
    }
    
    
    func viewController(
        _ viewController: UIViewController,
        didSelectVideoEpisodeWithID videoEpisodeID: NSManagedObjectID
    ) {
        guard
            let contentFeedItem = managedObjectContext.object(with: videoEpisodeID) as? ContentFeedItem,
            contentFeedItem.contentFeed?.isVideo == true
        else {
            preconditionFailure()
        }
        
        if let contentFeed = contentFeedItem.contentFeed {
            
            let videoFeed = VideoFeed.convertFrom(contentFeed:  contentFeed)
            let videoEpisode = Video.convertFrom(contentFeedItem: contentFeedItem, videoFeed: videoFeed)
            
            presentVideoPlayer(for: videoEpisode)
        }
    }
    
    func viewController(
        _ viewController: UIViewController,
        didSelectNewsletterFeedWithID newsletterFeedID: NSManagedObjectID
    ) {
        guard
            let contentFeed = managedObjectContext.object(with: newsletterFeedID) as? ContentFeed,
            contentFeed.isNewsletter
        else {
            preconditionFailure()
        }
        
        let newsletterFeed = NewsletterFeed.convertFrom(contentFeed: contentFeed)
        presentNewsletterFeedVC(for: newsletterFeed)
    }
    
    func viewController(
        _ viewController: UIViewController,
        didSelectNewsletterItemWithID newsletterItemID: NSManagedObjectID
    ) {
        guard
            let contentFeedItem = managedObjectContext.object(with: newsletterItemID) as? ContentFeedItem,
            let contentFeed = contentFeedItem.contentFeed,
            contentFeed.isNewsletter
        else {
            preconditionFailure()
        }
        
        let newsletterFeed = NewsletterFeed.convertFrom(contentFeed: contentFeed)
        
        let newsletterFeedItem = NewsletterItem.convertFrom(
            contentFeedItem: contentFeedItem,
            newsletterFeed: newsletterFeed
        )
        
        presentItemWebView(for: newsletterFeedItem)
    }
    
    func viewController(
        _ viewController: UIViewController,
        didSelectRecommendationWithId recommendationId: String,
        from recommendations: [RecommendationResult]
    ) {
        
    }
}


extension DashboardRootViewController {
    
    func presentPodcastPlayerFor(
        _ podcast: PodcastFeed
    ) {
        let podcastFeedVC = NewPodcastPlayerViewController.instantiate(
            podcast: podcast,
            delegate: self,
            boostDelegate: self,
            fromDashboard: true
        )
        
        podcastFeedVC.modalPresentationStyle = .automatic
        
        navigationController?
            .present(podcastFeedVC, animated: true)
    }
    
    
    private func presentVideoPlayer(
        for videoEpisode: Video
    ) {
        let viewController = VideoFeedEpisodePlayerContainerViewController
            .instantiate(
                videoPlayerEpisode: videoEpisode,
                dismissButtonStyle: .backArrow,
                delegate: self,
                boostDelegate: self
            )
        
        viewController.modalPresentationStyle = .automatic
        
        navigationController?
            .present(viewController, animated: true)
    }
    
    private func presentItemWebView(
        for newsletterItem: NewsletterItem
    ) {
        let viewController = NewsletterItemDetailViewController
            .instantiate(
                newsletterItem: newsletterItem,
                boostDelegate: self
            )
        
        viewController.modalPresentationStyle = .automatic
        
        navigationController?
            .present(viewController, animated: true)
    }
    
    private func presentNewsletterFeedVC(
        for newsletterFeed: NewsletterFeed
    ) {
        let viewController = NewsletterFeedContainerViewController
            .instantiate(
                newsletterFeed: newsletterFeed,
                delegate: self
            )
        
        viewController.modalPresentationStyle = .automatic
        
        navigationController?
            .present(viewController, animated: true)
    }
}
