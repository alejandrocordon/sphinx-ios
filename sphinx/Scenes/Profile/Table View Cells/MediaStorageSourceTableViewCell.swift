//
//  MediaStorageSourceTableViewCell.swift
//  sphinx
//
//  Created by James Carucci on 5/23/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

protocol MediaStorageSourceTableViewCellDelegate{
    func didTapItemDelete(index:Int)
}

class MediaStorageSourceTableViewCell: UITableViewCell {
    
    @IBOutlet weak var mediaSourceLabel: UILabel!
    @IBOutlet weak var mediaSourceSizeLabel: UILabel!
    @IBOutlet weak var initialsLabel: UILabel!
    @IBOutlet weak var squareImageView: UIImageView!
    @IBOutlet weak var disclosureImageView: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!
    
    @IBOutlet weak var chatAvatarImageView1: UIImageView!
    @IBOutlet weak var chatAvatarImageView2: UIImageView!
    @IBOutlet weak var chatAvatarImageView3: UIImageView!
    
    var index : Int? = nil
    var delegate: MediaStorageSourceTableViewCellDelegate? = nil
    
    static let reuseID = "MediaStorageSourceTableViewCell"

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        self.mediaSourceLabel.text = ""
        self.mediaSourceSizeLabel.text = ""
        self.squareImageView.image = nil
    }
    
    func configure(forSource:StorageManagerMediaSource){
        switch(forSource){
        case .chats:
            mediaSourceLabel.text = "Chats"
            squareImageView.isHidden = true
            
            chatAvatarImageView1.image = #imageLiteral(resourceName: "appPinIcon")
            chatAvatarImageView2.image = #imageLiteral(resourceName: "appPinIcon")
            chatAvatarImageView3.image = #imageLiteral(resourceName: "appPinIcon")
            
            let urls = StorageManager.sharedManager.getTop3ChatImages()
            if let url = URL(string: urls[0]){
                chatAvatarImageView1.sd_setImage(with: url, placeholderImage: #imageLiteral(resourceName: "appPinIcon"), context: nil)
                chatAvatarImageView1.layer.borderWidth = 2.0
                chatAvatarImageView1.layer.borderColor = UIColor.Sphinx.Body.cgColor
                chatAvatarImageView1.makeCircular()
                chatAvatarImageView1.isHidden = false
            }
            
            if let url2 = URL(string: urls[1]){
                chatAvatarImageView2.sd_setImage(with: url2, placeholderImage: #imageLiteral(resourceName: "appPinIcon"), context: nil)
                chatAvatarImageView2.layer.borderWidth = 2.0
                chatAvatarImageView2.layer.borderColor = UIColor.Sphinx.Body.cgColor
                chatAvatarImageView2.makeCircular()
                chatAvatarImageView2.isHidden = false
            }
            if let url3 = URL(string: urls[2]){
                chatAvatarImageView3.sd_setImage(with: url3, placeholderImage: #imageLiteral(resourceName: "appPinIcon"), context: nil)
                chatAvatarImageView3.layer.borderWidth = 2.0
                chatAvatarImageView3.layer.borderColor = UIColor.Sphinx.Body.cgColor
                chatAvatarImageView3.makeCircular()
                chatAvatarImageView3.isHidden = false
            }
            
            //squareImageView.image = StorageManager.sharedManager.getTop3ChatImages()// #imageLiteral(resourceName: "appPinIcon")
            squareImageView.makeCircular()
            break
        case .podcasts:
            mediaSourceLabel.text = "Podcasts"
            squareImageView.image = #imageLiteral(resourceName: "podcastTypeIcon")
            squareImageView.layer.cornerRadius = 6
            break
        }
    }
    
    func configure(forChat:Chat,items:[StorageManagerItem]){
        
        let name = forChat.getName()
        mediaSourceLabel.text = name
        
        
        mediaSourceSizeLabel.text = formatBytes(Int(StorageManager.sharedManager.getItemGroupTotalSize(items: items)))

        if let stringURL = forChat.getPhotoUrl(),
           let imageURL = URL(string:  stringURL){
            print(name)
            squareImageView.sd_setImage(with: imageURL)
            initialsLabel.isHidden = true
        }
        else{
            let name = name
            let color = UIColor.getColorFor(key: name)
            initialsLabel.textAlignment = .center
            initialsLabel.makeCircular()
            squareImageView.isHidden = true
            initialsLabel.isHidden = false
            initialsLabel.backgroundColor = color
            initialsLabel.textColor = UIColor.white
            initialsLabel.text = name.getInitialsFromName()
        }
        squareImageView.makeCircular()
        let mediaSizeText = formatBytes(Int(StorageManager.sharedManager.getItemGroupTotalSize(items: items)*1e6))
        mediaSourceSizeLabel.text = (mediaSizeText == "0 MB") ? "<1MB" : mediaSizeText
    }
    
    
    func configure(podcastFeed:PodcastFeed,items:[StorageManagerItem]){
        mediaSourceLabel.text = podcastFeed.title
        if let imageURL = URL(string: podcastFeed.imageToShow ?? ""){
            squareImageView.sd_setImage(with: imageURL)
        }
        squareImageView.layer.cornerRadius = 6
        let mediaSizeText = formatBytes(Int(StorageManager.sharedManager.getItemGroupTotalSize(items: items)*1e6))
        mediaSourceSizeLabel.text = (mediaSizeText == "0 MB") ? "<1MB" : mediaSizeText
    }
    
    func configure(podcastEpisode:PodcastEpisode,item:StorageManagerItem,index:Int){
        mediaSourceLabel.text = podcastEpisode.title
        if let imageURL = URL(string: podcastEpisode.imageToShow ?? ""){
            squareImageView.sd_setImage(with: imageURL)
        }
        squareImageView.layer.cornerRadius = 6
        mediaSourceSizeLabel.text = formatBytes(Int(StorageManager.sharedManager.getItemGroupTotalSize(items: [item])*1e6))
        
        self.index = index
        
        disclosureImageView.isHidden = true
        deleteButton.isHidden = false
    }
    
    
    @IBAction func deleteItemTapped(_ sender: Any) {
        if let index = index{
            delegate?.didTapItemDelete(index: index)
        }
    }
    
}
