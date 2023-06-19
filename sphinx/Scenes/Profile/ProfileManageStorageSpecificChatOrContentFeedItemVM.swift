//
//  ProfileManageStorageSpecificChatOrContentFeedItemVM.swift
//  sphinx
//
//  Created by James Carucci on 5/24/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit

class ProfileManageStorageSpecificChatOrContentFeedItemVM : NSObject{
    
    var vc : ProfileManageStorageSpecificChatOrContentFeedItemVC
    var podcastTableView : UITableView
    var imageCollectionView : UICollectionView
    var filesTableView : UITableView
    
    
    var teedUpIndex : Int? = nil
    var mediaItems : [StorageManagerItem] = []{
        didSet{
            selectedStatus = mediaItems.map({_ in return false})
        }
    }
    
    var fileItems : [StorageManagerItem] = []{
        didSet{
            selectedStatus = mediaItems.map({_ in return false})
        }
    }
    
    var selectedStatus : [Bool] = []{
        didSet{
            vc.deletionSummaryView.isHidden = (getIsSelectingImages()) ? false : true
            vc.view.bringSubviewToFront(vc.deletionSummaryView)
            vc.updateDeletionSummaryLabel()
            imageCollectionView.reloadData()
        }
    }
    
    func removeSelectedItems() {
        var indicesToRemove: [Int] = []
        
        for (index, isSelected) in selectedStatus.enumerated() {
            if isSelected {
                indicesToRemove.append(index)
            }
        }
        
        // Sort the indices in descending order
        indicesToRemove.sort(by: >)
        
        // Remove the selected items from the items array
        for index in indicesToRemove {
            mediaItems.remove(at: index)
        }
        
        // Reset the selected status
        selectedStatus = mediaItems.map({ _ in return false })
        
        // Reload the collection view or table view if needed
        imageCollectionView.reloadData()
        podcastTableView.reloadData()
    }
    
    func getSelectedCachedMedia()->[CachedMedia]{
        return getSelectedItems().compactMap({$0.cachedMedia})
    }
    
    func getSelectedItems() -> [StorageManagerItem] {
        var selectedItems: [StorageManagerItem] = []
        
        for (index, isSelected) in selectedStatus.enumerated() {
            if isSelected {
                selectedItems.append(mediaItems[index])
            }
        }
        
        return selectedItems
    }

    
    func getIsSelectingImages()->Bool{
        let isSelectingImages = selectedStatus.filter({$0 == true}).count > 0
        return isSelectingImages
    }
    
    func getSelectionSize()->Double{
        var result : Double = 0.0
        for i in 0..<selectedStatus.count{
            result += (selectedStatus[i]) ? mediaItems[i].sizeMB : 0
        }
        return (result)
    }
    
    var sourceType : StorageManagerMediaSource
    
    init(
        vc: ProfileManageStorageSpecificChatOrContentFeedItemVC,
        tableView: UITableView,
        imageCollectionView: UICollectionView,
        filesTableView : UITableView,
        source: StorageManagerMediaSource
    ) {
        self.vc = vc
        self.podcastTableView = tableView
        self.imageCollectionView = imageCollectionView
        self.filesTableView = filesTableView
        self.sourceType = source
    }
    
    func finishSetup(items : [StorageManagerItem]){
        self.mediaItems = items.sorted(by: {$0.date > $1.date})
        
        if (sourceType == .podcasts) {
            podcastTableView.delegate = self
            podcastTableView.dataSource = self
            
            podcastTableView.register(UINib(nibName: "MediaStorageSourceTableViewCell", bundle: nil), forCellReuseIdentifier: MediaStorageSourceTableViewCell.reuseID)
        } else if (sourceType == .chats) {
            let flow = AlignedCollectionViewFlowLayout(horizontalAlignment: .left)
            flow.minimumLineSpacing = 0
            flow.minimumInteritemSpacing = 0
            
            imageCollectionView.registerCell(ChatImageCollectionViewCell.self)
            imageCollectionView.delegate = self
            imageCollectionView.dataSource = self
            imageCollectionView.collectionViewLayout = flow
            podcastTableView.isHidden = true
            
            filesTableView.delegate = self
            filesTableView.dataSource = self
            filesTableView.register(UINib(nibName: "MediaStorageSourceTableViewCell", bundle: nil), forCellReuseIdentifier: MediaStorageSourceTableViewCell.reuseID)
        }
    }
    
    func getEpisodeForItem(item:StorageManagerItem)->PodcastEpisode?{
        if let itemID = item.uid,
           let cfi = FeedsManager.sharedInstance.fetchPodcastEpisode(itemID: itemID)
           {
            let episode = PodcastEpisode.convertFrom(contentFeedItem: cfi)
            return episode
        }
        
        return nil
    }
    
}


extension ProfileManageStorageSpecificChatOrContentFeedItemVM : UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: MediaStorageSourceTableViewCell.reuseID,
            for: indexPath
        ) as! MediaStorageSourceTableViewCell
        
        switch(vc.sourceType){
        case .podcasts:
            let item = mediaItems[indexPath.row]
            if let episode = getEpisodeForItem(item: item){
                cell.configure(podcastEpisode: episode, item: item, index: indexPath.row)
                cell.delegate = self
            }
            cell.selectionStyle = .none
            return cell
        case .chats:
            let testFile = StorageManagerItem(source: .chats, type: .other, sizeMB: 150.0, label: "", date: Date())
            let fileTypes = ["PDF", "DOC", "XLS", "ZIP"]
            let randomIndex = Int.random(in: 0..<fileTypes.count)
            cell.configure(fileName: "My File", fileType: fileTypes[randomIndex], item: testFile)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch(vc.sourceType){
        case .podcasts:
            return mediaItems.count
            break
        case .chats:
            return 100
            break
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(sourceType == .podcasts){
            print(mediaItems[indexPath.row])
            if let sourcePath = mediaItems[indexPath.row].sourceFilePath{
                if let pair = StorageManager.sharedManager.getFeedItemPairForString(string: sourcePath),
                pair.count > 1{
                    let feedID = pair[0]
                    let itemID = pair[1].replacingOccurrences(of: ".mp3", with: "")
                    if let feed = FeedsManager.sharedInstance.fetchFeeds().filter({$0.feedID == feedID}).first{
                        let pf = PodcastFeed.convertFrom(contentFeed: feed)
                        self.vc.presentPodcastPlayerFor(pf,itemID: itemID)
                    }
                }
            }
        }
    }
    
    
}

extension ProfileManageStorageSpecificChatOrContentFeedItemVM : UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mediaItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ChatImageCollectionViewCell.reuseID,
            for: indexPath
        ) as! ChatImageCollectionViewCell
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        if let cell = cell as? ChatImageCollectionViewCell,
           let cm = mediaItems[indexPath.row].cachedMedia{
            cell.configure(cachedMedia: cm, size: getSize(),selectionStatus: selectedStatus[indexPath.row], memorySizeMB: mediaItems[indexPath.row].sizeMB)
        }
    }
    
    func getSize() -> CGSize {
        let collectionViewWidth = self.imageCollectionView.bounds.width
        let cellWidth: CGFloat = (collectionViewWidth / 3)

        let cellHeight = cellWidth
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return getSize()
    }

    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedStatus[indexPath.row] = !selectedStatus[indexPath.row]
    }
}


extension ProfileManageStorageSpecificChatOrContentFeedItemVM : MediaStorageSourceTableViewCellDelegate{
    func didTapItemDelete(index: Int) {
        teedUpIndex = index
        vc.mediaDeletionConfirmationView.batchState = .single
        vc.mediaDeletionConfirmationView.source = self.sourceType
        vc.showDeletionWarningAlert(type: .audio)
    }
    
    func finalizeEpisodeDelete(){
        if let index = teedUpIndex,
           let sourcePath = mediaItems[index].sourceFilePath{
            teedUpIndex = nil
            vc.mediaDeletionConfirmationView.batchState = nil
            StorageManager.sharedManager.deletePodsWithID(
                fileName: sourcePath,
                successCompletion: {
                    self.handleConfirmDelete(index: index)
                },
                failureCompletion: {
                    AlertHelper.showAlert(title: "Error", message: "Could not delete the content. Please try again later.")
                }
            )
        }
    }
    
    func handleConfirmDelete(index:Int){
        vc.mediaDeletionConfirmationView.spaceFreedString = formatBytes(Int(mediaItems[index].sizeMB * 1e6))
        self.mediaItems.remove(at: index)
        self.vc.mediaDeletionConfirmationView.state = .finished
        self.finishSetup(items: self.mediaItems)
        self.vc.setupViewAndModels()
        self.podcastTableView.reloadData()
        
        StorageManager.sharedManager.refreshAllStoredData(completion: {
        })
    }
}
