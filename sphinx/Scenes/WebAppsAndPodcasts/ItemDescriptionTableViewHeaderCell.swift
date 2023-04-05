//
//  ItemDescriptionTableViewHeaderCell.swift
//  sphinx
//
//  Created by James Carucci on 4/4/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

protocol ItemDescriptionTableViewHeaderCellDelegate{
    func itemShareTapped(episode:PodcastEpisode)
    func itemShareTapped(video:Video)
}

class ItemDescriptionTableViewHeaderCell: UITableViewCell {
    static let reuseID = "ItemDescriptionTableViewHeaderCell"
    
    @IBOutlet weak var podcastTitleLabel: UILabel!
    @IBOutlet weak var episodeTitleLabel: UILabel!
    @IBOutlet weak var playButton: UILabel!
    @IBOutlet weak var mediaTypeIcon: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var dotView: UIView!
    @IBOutlet weak var timeRemaining: UILabel!
    
    weak var episode:PodcastEpisode?=nil
    weak var video:Video? = nil
    var delegate:ItemDescriptionTableViewHeaderCellDelegate? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func configureView(podcast:PodcastFeed,episode:PodcastEpisode){
        self.episode = episode
        podcastTitleLabel.text = podcast.title
        episodeTitleLabel.text = episode.title
        playButton.makeCircular()
        dotView.makeCircular()
        mediaTypeIcon.layer.cornerRadius = 3.0
        dateLabel.text = episode.dateString
        
        let duration = episode.duration ?? 0
        let currentTime = episode.currentTime ?? 0
        
        let timeString = (duration - currentTime).getEpisodeTimeString(
            isOnProgress: currentTime > 0
        )
        timeRemaining.text = timeString
    }
    
    func configureView(videoFeed:VideoFeed,video:Video){
        self.video = video
        podcastTitleLabel.text = videoFeed.title
        episodeTitleLabel.text = video.title
        playButton.makeCircular()
        dotView.makeCircular()
        mediaTypeIcon.layer.cornerRadius = 3.0
        mediaTypeIcon.image = #imageLiteral(resourceName: "youtubeVideoTypeIcon")
        //dateLabel.text = video.dateString
        
        timeRemaining.isHidden = true
    }
    @IBAction func shareButton(_ sender: Any) {
        if let episode = self.episode{
            delegate?.itemShareTapped(episode: episode)
        }
        else if let video = self.video{
            delegate?.itemShareTapped(video: video)
        }
    }
    
}
