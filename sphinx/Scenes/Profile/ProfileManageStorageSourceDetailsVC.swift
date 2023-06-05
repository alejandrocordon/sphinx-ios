//
//  ProfileManageStorageSourceDetailsVC.swift
//  sphinx
//
//  Created by James Carucci on 5/23/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit

class ProfileManageStorageSourceDetailsVC : UIViewController{
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var mediaSourceDetailsTableView: UITableView!
    @IBOutlet weak var mediaSourceTotalSizeLabel: UILabel!
    @IBOutlet weak var mediaDeletionConfirmationView: MediaDeletionConfirmationView!
    var overlayView : UIView? = nil
    
    var source : StorageManagerMediaSource = .chats
    var totalSize : Double = 0.0
    var isFirstLoad : Bool = true
    
    lazy var vm : ProfileManageStorageSourceDetailsVM = {
        return ProfileManageStorageSourceDetailsVM(vc: self, tableView: mediaSourceDetailsTableView, source: self.source)
    }()
    
    static func instantiate(items:[StorageManagerItem],
                            source:StorageManagerMediaSource,
                            sourceTotalSize:Double)->ProfileManageStorageSourceDetailsVC{
        let viewController = StoryboardScene.Profile.profileManageStorageSourceDetailsVC.instantiate()
        viewController.source = source
        viewController.totalSize = sourceTotalSize
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //view.backgroundColor = .magenta
        if(isFirstLoad == true){
            setupView()
            vm.finishSetup()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if(isFirstLoad == false){
            vm.finishSetup()
            mediaSourceDetailsTableView.reloadData()
        }
        isFirstLoad = false
    }
    
    func setupView(){
        switch(source){
        case .chats:
            headerLabel.text = "Chats"
            break
        case .podcasts:
            headerLabel.text = "Podcasts"
            break
        }
        mediaSourceTotalSizeLabel.text = formatBytes(Int(totalSize*1e6))
        hideDeletionWarningAlert()
    }
    
    func showDeletionWarningAlert(type:StorageManagerMediaType){
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: {
            self.overlayView = UIView(frame: self.view.frame)
            if let overlayView = self.overlayView{
                overlayView.backgroundColor = .black
                overlayView.isUserInteractionEnabled = false
                overlayView.alpha = 0.8
                self.view.addSubview(overlayView)
                self.view.bringSubviewToFront(overlayView)
            }
            self.view.bringSubviewToFront(self.mediaDeletionConfirmationView)
            self.mediaDeletionConfirmationView.layer.zPosition = 1000
            self.mediaDeletionConfirmationView.delegate = self
            self.mediaDeletionConfirmationView.type = type
            self.mediaDeletionConfirmationView.isHidden = false
            //self.mediaDeletionConfirmationView.contentView.backgroundColor = .black
        })
    }
    
    func hideDeletionWarningAlert(){
        self.overlayView?.removeFromSuperview()
        self.overlayView = nil
        
        self.mediaDeletionConfirmationView.isHidden = true
    }
    
    
    @IBAction func backTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func deleteAllTapped(_ sender: Any) {
        print("deleteAllTapped")
        let itemDescription = (source == .chats) ? "chat.media".localized : "podcasts"
        switch(self.source){
            case .chats:
                AlertHelper.showTwoOptionsAlert(
                    title: "Are you sure?",
                    message: "Proceeding will delete all of your \(itemDescription) from this device. This cannot be undone.",
                    confirm: {
                        StorageManager.sharedManager.deleteAllImages(completion: {
                            StorageManager.sharedManager.deleteAllVideos(completion: {
                                StorageManager.sharedManager.refreshAllStoredData(completion: {
                                    self.handleReset()
                                })
                            })
                        })
                })
                break
                
            case .podcasts:
                self.showDeletionWarningAlert(type: .audio)
                break
        }
    }
    
    func handleReset(){
        StorageManager.sharedManager.refreshAllStoredData {
            self.vm.finishSetup()
            self.totalSize = StorageManager.sharedManager.getItemGroupTotalSize(items: self.vm.getSourceItems())
            self.setupView()
            self.vm.tableView.reloadData()
        }
    }
    
    func showItemSpecificDetails(podcastFeed:PodcastFeed?,chat:Chat?,sourceType:StorageManagerMediaSource,items:[StorageManagerItem]){
        let vc = ProfileManageStorageSpecificChatOrContentFeedItemVC.instantiate(podcastFeed: podcastFeed, chat: chat, sourceType: sourceType,items: items)
        vc.delegate = self
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}


extension ProfileManageStorageSourceDetailsVC : ProfileManageStorageSpecificChatOrContentFeedItemVCDelegate{
    func finishedDeleteAll() {
        self.navigationController?.popViewController(animated: true)
    }
}

extension ProfileManageStorageSourceDetailsVC : MediaDeletionConfirmationViewDelegate{
    func cancelTapped() {
        self.hideDeletionWarningAlert()
    }
    
    func deleteTapped() {
        mediaDeletionConfirmationView.isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: {
            self.mediaDeletionConfirmationView.isLoading = false
        })
//        StorageManager.sharedManager.deleteAllAudioFiles(completion: {
//            self.handleReset()
//        })
    }
    
    
}
