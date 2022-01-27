//
//  FeedBoostHelper.swift
//  sphinx
//
//  Created by Tomas Timinskas on 20/01/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import Foundation
import CoreData

class FeedBoostHelper : NSObject {
    
    var contentFeed: ContentFeed? = nil
    var chat: Chat? = nil
    
    func configure(
        with objectID: NSManagedObjectID,
        and chat: Chat?
    ) {
        self.contentFeed = CoreDataManager.sharedManager.getObjectWith(objectId: objectID)
        self.chat = chat
    }
    
    func getBoostMessage(
        itemID: String,
        amount: Int,
        currentTime: Int = 0
    ) -> String? {
        
        guard let contentFeed = self.contentFeed else {
            return nil
        }
        
        if amount == 0 {
            return nil
        }
        
        let feedID = contentFeed.feedID
        
        return "{\"feedID\":\"\(feedID)\",\"itemID\":\"\(itemID)\",\"ts\":\(currentTime),\"amount\":\(amount)}"
    }
    
    func processPayment(
        itemID: String,
        amount: Int,
        currentTime: Int = 0
    ) {
        processPaymentsFor(
            itemID: itemID,
            amount: amount,
            currentTime: currentTime
        )
    }
    
    func processPaymentsFor(
        itemID: String,
        amount: Int,
        currentTime: Int
    ) {
        let destinations = contentFeed?.destinationsArray ?? []
        
        if
            let _ = contentFeed,
            destinations.isEmpty == false
        {
            streamSats(
                feedDestinations: destinations,
                amount: amount,
                itemID: itemID,
                currentTime: currentTime
            )
        }
    }
    
    func streamSats(
        feedDestinations: [ContentFeedPaymentDestination],
        amount: Int,
        itemID: String,
        currentTime: Int
    ) {
        
        guard let feedID = contentFeed?.feedID else {
            return
        }
        
        var destinations = [[String: AnyObject]]()
        
        for d in feedDestinations {
            let destinationParams: [String: AnyObject] = ["address": (d.address ?? "") as AnyObject, "split": (d.split) as AnyObject, "type": (d.type ?? "") as AnyObject]
            destinations.append(destinationParams)
        }
        
        var params: [String: AnyObject] = ["destinations": destinations as AnyObject, "amount": amount as AnyObject, "chat_id": (chat?.id ?? -1) as AnyObject]
        
        params["text"] = "{\"feedID\":\"\(feedID)\",\"itemID\":\"\(itemID)\",\"ts\":\(currentTime)}" as AnyObject
            
        API.sharedInstance.streamSats(params: params, callback: {}, errorCallback: {})
    }
    
    func sendBoostMessage(
        message: String,
        completion: @escaping ((TransactionMessage?, Bool) -> ())
    ) {
        if let chat = chat {
            let boostType = TransactionMessage.TransactionMessageType.boost.rawValue
            let provisionalMessage = TransactionMessage.createProvisionalMessage(messageContent: message, type: boostType, date: Date(), chat: chat)
            
            let messageType = TransactionMessage.TransactionMessageType(fromRawValue: provisionalMessage?.type ?? 0)
            guard let params = TransactionMessage.getMessageParams(contact: nil, chat: chat, type: messageType, text: message) else {
                completion(provisionalMessage, false)
                return
            }
            
            API.sharedInstance.sendMessage(params: params, callback: { m in
                if let message = TransactionMessage.insertMessage(m: m, existingMessage: provisionalMessage).0 {
                    message.setPaymentInvoiceAsPaid()
                    
                    completion(message, true)
                    
                }
            }, errorCallback: {
                 if let provisionalMessage = provisionalMessage {
                    provisionalMessage.status = TransactionMessage.TransactionMessageStatus.failed.rawValue
                    
                    completion(provisionalMessage, false)
                 }
            })
        }
    }
}