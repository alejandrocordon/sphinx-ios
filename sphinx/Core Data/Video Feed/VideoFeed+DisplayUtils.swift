// VideoFeed+Computedsi.swift
//
// Created by CypherPoet.
// ✌️
//
    
import UIKit


extension VideoFeed {
    
    var avatarImagePlaceholder: UIImage? {
        UIImage(named: "userAvatar")
    }
    
    
    var titleForDisplay: String { title ?? "Untitled" }
}