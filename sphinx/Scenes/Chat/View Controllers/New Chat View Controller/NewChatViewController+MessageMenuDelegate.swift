//
//  NewChatViewController+MessageMenuDelegate.swift
//  sphinx
//
//  Created by Tomas Timinskas on 15/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation

extension NewChatViewController : MessageOptionsVCDelegate {
    func shouldDeleteMessage(message: TransactionMessage) {
        chatViewModel.shouldDeleteMessage(message: message)
    }
    
    func shouldReplyToMessage(message: TransactionMessage) {
        chatViewModel.replyingTo = message
        bottomView.configureReplyViewFor(message: message, withDelegate: self)
        shouldAdjustTableViewTopInset()
    }
    
    func shouldBoostMessage(message: TransactionMessage) {
        chatViewModel.shouldBoostMessage(message: message)
    }
    
    func shouldResendMessage(message: TransactionMessage) {
        chatViewModel.shouldResendMessage(message: message)
    }
    
    func shouldFlagMessage(message: TransactionMessage) {
        chatViewModel.sendFlagMessageFor(message)
    }
    
    func shouldRemoveWindow() {}
}
