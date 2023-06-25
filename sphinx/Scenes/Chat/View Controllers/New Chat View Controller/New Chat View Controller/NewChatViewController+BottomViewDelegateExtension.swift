//
//  NewChatViewController+BottomViewDelegateExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 16/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

extension NewChatViewController : ChatMessageTextFieldViewDelegate {
    func shouldSendMessage(text: String, type: Int, completion: @escaping (Bool) -> ()) {
        bottomView.resetReplyView()
        
        chatViewModel.shouldSendMessage(text: text, type: type, completion: { success in
            
            if success {
                self.scrollToBottomAfterSend()
            }
            
            completion(success)
        })
    }
    
    func scrollToBottomAfterSend() {
        DelayPerformedHelper.performAfterDelay(seconds: 0.1, completion: {
            self.chatTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        })
    }
    
    func didTapAttachmentsButton(text: String?) {
        if AttachmentsManager.sharedInstance.uploading || self.presentedViewController != nil {
            return
        }
        
        let viewController = ChatAttachmentViewController.instantiate(
            delegate: self,
            chatId: self.chat?.id,
            text: text,
            replyingMessageId: nil
        )
        
        viewController.modalPresentationStyle = .overCurrentContext
        
        self.present(
            viewController,
            animated: false
        )
    }
    
    func shouldStartRecording() {
        chatViewModel.shouldStartRecordingWith(delegate: self)
    }
    
    func shouldStopAndSendAudio() {
        chatViewModel.shouldStopAndSendAudio()
    }
    
    func shouldCancelRecording() {
        chatViewModel.shouldCancelRecording()
    }
}

extension NewChatViewController : AudioHelperDelegate {
    func didStartRecording(_ success: Bool) {
        if !success {
            messageBubbleHelper.showGenericMessageView(text: "microphone.permission.denied".localized, delay: 5)
        }
    }
    
    func didFinishRecording(_ success: Bool) {
        if success {
            bottomView.clearMessage()
            bottomView.resetReplyView()
            
            chatViewModel.didFinishRecording()
        }
    }
    
    func audioTooShort() {
        let windowInset = getWindowInsets()
        let y = WindowsManager.getWindowHeight() - windowInset.bottom - bottomView.frame.size.height
        messageBubbleHelper.showAudioTooltip(y: y)
    }
    
    func recordingProgress(minutes: String, seconds: String) {
        bottomView.updateRecordingAudio(minutes: minutes, seconds: seconds)
    }
}

extension NewChatViewController : MessageReplyViewDelegate {
    func didCloseView() {
        chatViewModel.resetReply()
        shouldAdjustTableViewTopInset()
    }
    
    func shouldScrollTo(message: TransactionMessage) {}
}