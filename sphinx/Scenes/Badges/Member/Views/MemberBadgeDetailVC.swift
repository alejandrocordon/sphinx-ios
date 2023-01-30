//
//  MemberBadgeDetailVC.swift
//  sphinx
//
//  Created by James Carucci on 1/30/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit

class MemberBadgeDetailVC : UIViewController{
    
    
    @IBOutlet weak var memberImageView: UIImageView!
    @IBOutlet weak var sendSatsButton: UIButton!
    @IBOutlet weak var earnBadgesButton: UIButton!
    
    static func instantiate(
        rootViewController: RootViewController
    ) -> UIViewController {
        let viewController = StoryboardScene.BadgeManagement.memberBadgeDetailVC.instantiate()
        
        return viewController
    }
    
    override func viewDidLoad() {
        //self.view.backgroundColor = .green
        configHeaderView()
    }
    
    func configHeaderView(){
        //Member Image
        memberImageView.contentMode = .scaleAspectFill
        memberImageView.sd_setImage(with: URL(string: "https://us.123rf.com/450wm/fizkes/fizkes2010/fizkes201001384/fizkes201001384.jpg?ver=6"))
        memberImageView.makeCircular()
        
        //Send Sats
        sendSatsButton.layer.cornerRadius = 13.0

        //Earn Badges
        earnBadgesButton.layer.borderWidth = 1.0
        earnBadgesButton.layer.borderColor = UIColor.Sphinx.MainBottomIcons.cgColor
        earnBadgesButton.layer.cornerRadius = 13.0
        
    }
    
}
