//
//  DiscoverTribesTableViewCell.swift
//  sphinx
//
//  Created by James Carucci on 1/4/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

protocol DiscoverTribesCellDelegate{
    func handleJoin(url:URL)
}

class DiscoverTribesTableViewCell: UITableViewCell {
    
    
    @IBOutlet weak var tribeImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var joinButton: UIButton!
    var cellURL : URL? = nil
    var delegate : DiscoverTribesCellDelegate? = nil
    
    
    static let reuseID = "DiscoverTribesTableViewCell"
    
    static let nib: UINib = {
        UINib(nibName: "DiscoverTribesTableViewCell", bundle: nil)
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(tribeData:DiscoverTribeData,wasJoined:Bool){
        if let urlString = tribeData.imgURL,
           let url = URL(string: urlString) {
            
            tribeImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "tribePlaceholder"))
            tribeImageView.layer.cornerRadius = 24
            tribeImageView.clipsToBounds = true
        }
        
        titleLabel.text = tribeData.name
        descriptionLabel.text = tribeData.description
        
        configureJoinButton(tribeData: tribeData,wasJoined:wasJoined)
        styleCell()
    }
    
    func styleCell(){
        self.backgroundColor = UIColor.Sphinx.Body
        self.contentView.backgroundColor = UIColor.Sphinx.Body
        self.titleLabel.textColor = UIColor.Sphinx.PrimaryText
        self.descriptionLabel.textColor = UIColor.Sphinx.SecondaryText
    }
    
    func configureJoinButton(tribeData:DiscoverTribeData,wasJoined:Bool){
        if wasJoined{
            joinButton.titleLabel?.textColor = .black
            joinButton.backgroundColor = UIColor.Sphinx.ReceivedMsgBG
            joinButton.setTitle("Open", for: .normal)
        }
        else{
            joinButton.titleLabel?.textColor = .white
            joinButton.backgroundColor = UIColor.Sphinx.PrimaryBlue
        }
        
        joinButton.titleLabel?.font = UIFont(name: "Roboto-Bold", size: 14.0)
        joinButton.layer.cornerRadius = 15.0
        let host = tribeData.host ?? API.kTribesServerBaseURL.replacingOccurrences(of: "https://", with: "")
        if let uuid = tribeData.uuid {
            cellURL = URL(string: "sphinx.chat://?action=tribe&uuid=\(uuid)&host=\(host)")
            joinButton.addTarget(self, action: #selector(handleJoinTap), for: .touchUpInside)
        } else {
            joinButton.backgroundColor = UIColor.lightGray
            joinButton.isEnabled = false
        }
    }
    
    @objc func handleJoinTap(){
        if let valid_url = cellURL{
            self.delegate?.handleJoin(url: valid_url)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        joinButton.titleLabel?.textColor = .white
        joinButton.setTitle("Join", for: .normal)
        tribeImageView.image = nil
        descriptionLabel.text = ""
        titleLabel.text = ""
    }
    
}
