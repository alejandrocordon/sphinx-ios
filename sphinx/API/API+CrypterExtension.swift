//
//  API+CrypterExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 11/07/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import Foundation
import SwiftyJSON

extension API {
    func getHardwarePublicKey(
        url: String,
        callback: @escaping HardwarePublicKeyCallback,
        errorCallback: @escaping EmptyCallback
    ) {
        let tribeRequest : URLRequest? = createRequest(url, bodyParams: nil, method: "GET")
        
        guard let request = tribeRequest else {
            errorCallback()
            return
        }
        
        //NEEDS TO BE CHANGED
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let response = data as? NSDictionary {
                    if let publicKey = response["pubkey"] as? String {
                        callback(publicKey)
                        return
                    }
                } else {
                    errorCallback()
                }
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    func sendSeedToHardware(
        url: String,
        hardwarePostDto: CrypterManager.HardwarePostDto,
        callback: @escaping HardwareSeedCallback
    ) {
        
        guard let encryptedSeed = hardwarePostDto.encryptedSeed,
              let networkName = hardwarePostDto.networkName,
              let networkPassword = hardwarePostDto.networkPassword,
              let publicKey = hardwarePostDto.publicKey else {
            
            callback(false)
            return
        }
        
        let broker = hardwarePostDto.broker
        
        let params = "{\"seed\":\"\(encryptedSeed)\",\"ssid\":\"\(networkName)\",\"pass\":\"\(networkPassword)\",\"broker\":\"\(broker)\",\"pubkey\":\"\(publicKey)\",\"network\":\"regtest\"}"
        
        let url = "\(url)?config=\(params.urlEncode()!)"
        let request : URLRequest? = createRequest(url, bodyParams: nil, method: "POST")
        
        guard let request = request else {
            callback(false)
            return
        }
        
        //NEEDS TO BE CHANGED
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let _ = data as? NSDictionary {
                    callback(true)
                } else {
                    callback(false)
                }
            case .failure(_):
                callback(false)
            }
        }
    }
}