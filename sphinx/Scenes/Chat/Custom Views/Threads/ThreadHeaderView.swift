//
//  ThreadHeaderView.swift
//  sphinx
//
//  Created by James Carucci on 7/19/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit
import SDWebImage

protocol ThreadHeaderViewDelegate : NSObject{
    func didTapBackButton()
}

class ThreadHeaderView : UIView {
    
    var delegate : ThreadHeaderViewDelegate? = nil
    
    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var messageLabelContainer: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var senderContainer: UIView!
    @IBOutlet weak var senderNameLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var senderAvatarView: ChatAvatarView!
    
    var isExpanded : Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("ThreadHeaderView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    func configureWith(
        message: TransactionMessage,
        delegate: ThreadHeaderViewDelegate
    ){
        self.delegate = delegate
        
        messageLabel.text = message.bubbleMessageContentString
        timestampLabel.text = (message.date ?? Date()).getStringDate(format: "MMMM d yyyy 'at' h:mm a")
        
        guard let owner = UserContact.getOwner() else {
            return
        }
        
        if message.isIncoming(ownerId: owner.id) {
            let senderColor = ChatHelper.getSenderColorFor(message: message)
            
            senderAvatarView.configureForUserWith(
                color: senderColor,
                alias: message.senderAlias ?? "Unknow",
                picture: message.senderPic
            )
            
            senderNameLabel.text = message.senderAlias
        } else {
            let senderColor = owner.getColor()
            
            senderAvatarView.configureForUserWith(
                color: senderColor,
                alias: owner.nickname ?? "Unknow",
                picture: owner.getPhotoUrl()
            )
            
            senderNameLabel.text = owner.nickname
        }
        
        messageLabelContainer.isHidden = true
        senderContainer.isHidden = true
    }
    
    @IBAction func backButtonTouched() {
        delegate?.didTapBackButton()
    }
}
