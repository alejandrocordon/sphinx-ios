//
//  CrypterManager.swift
//  sphinx
//
//  Created by Tomas Timinskas on 12/07/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import Foundation
import UIKit
import HDWalletKit
import NetworkExtension
import CoreLocation

class CrypterManager : NSObject {
    
    struct HardwarePostDto {
        var ip:String? = nil
        var port:String = "1883"
        var broker:String = "127.0.0.1:1883"
        var networkName:String? = nil
        var networkPassword:String? = nil
        var publicKey: String? = nil
        var encryptedSeed: String? = nil
    }
    
    var locationManger: CLLocationManager?
    
    var vc: UIViewController! = nil
    var endCallback: () -> Void = {}
    
    var hardwarePostDto = HardwarePostDto()
    let newMessageBubbleHelper = NewMessageBubbleHelper()
    
    func startLocationManager(callback: () -> ()) {
        let status = CLLocationManager.authorizationStatus()
         if status == .authorizedWhenInUse {
             callback()
             return
         }

        guard locationManger == nil else {
            // If locationManager is being started for the second time, for instance in .confirmNetwork, don't set accuracy and delegate again.
            locationManger?.requestWhenInUseAuthorization()
            locationManger?.startUpdatingLocation()
            return
        }

        locationManger = CLLocationManager()
        locationManger?.delegate = self
        locationManger?.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManger?.requestWhenInUseAuthorization()
        locationManger?.startUpdatingLocation()
    }
    
    func setupSigningDevice(
        vc: UIViewController,
        callback: @escaping () -> ()
    ) {
        self.vc = vc
        self.endCallback = callback
        
        startLocationManager() {
            self.hardwarePostDto = HardwarePostDto()
            self.setupSigningDevice()
        }
    }
    
    func setupSigningDevice() {
        self.getWifiInfo() { network in
            self.promptForNetworkName(network?.ssid) {
                self.promptForNetworkPassword(network?.ssid) {
                    self.promptForHardwareIP() {
                        self.promptForHardwarePort {
                            self.testCrypter()
                        }
                    }
                }
            }
            
        }
    }
    
    func promptForHardwareIP(callback: @escaping () -> ()) {
        promptFor(
            "Lightning node IP",
            message: "Enter the IP of your lightning node",
            errorMessage: "Invalid IP",
            callback: { value in
                self.hardwarePostDto.ip = value
                callback()
            }
        )
    }
    
    func promptForHardwarePort(callback: @escaping () -> ()) {
        promptFor(
            "Lightning node Port",
            message: "nter the Port number of your lightning node",
            errorMessage: "Invalid IP",
            textFieldText: "1883",
            callback: { value in
                self.hardwarePostDto.port = value
                callback()
            }
        )
    }
    
    func getWifiInfo(callback: @escaping (NEHotspotNetwork?) -> ()) {
        if #available(iOS 14.0, *) {
            NEHotspotNetwork.fetchCurrent(completionHandler: { network in
                callback(network)
            })
        } else {
            callback(nil)
        }
    }
    
    func promptForNetworkName(
        _ networkName: String?,
        callback: @escaping () -> ()
    ) {
        promptFor(
            "WiFI network",
            message: "Please specify your WiFI network",
            errorMessage: "Invalid WiFi name",
            textFieldText: networkName,
            callback: { value in
                self.hardwarePostDto.networkName = value
                callback()
            }
        )
    }
    
    func promptForNetworkPassword(
        _ networkName: String?,
        callback: @escaping () -> ()
    ) {
        promptFor(
            "WiFi password",
            message: "Enter the WiFi password for \(networkName ?? "your network")",
            errorMessage: "Invalid WiFi password",
            secureEntry: true,
            callback: { value in
                self.hardwarePostDto.networkPassword = value
                callback()
            }
        )
    }
    
    func promptFor(
        _ title: String,
        message: String,
        errorMessage: String,
        textFieldText: String? = nil,
        secureEntry: Bool = false,
        callback: @escaping (String) -> ()) {
            
        AlertHelper.showPromptAlert(
            title: title,
            message: message,
            textFieldText: textFieldText,
            secureEntry: secureEntry,
            on: vc,
            confirm: { value in
                if let value = value, !value.isEmpty {
                    callback(value)
                } else {
                    self.showErrorWithMessage(errorMessage)
                }
            },
            cancel: {}
        )
        
    }
    
    public func generateAndPersistWalletMnemonic() -> String {
        let mnemonic = UserData.sharedInstance.getMnemonic() ?? Mnemonic.create()
        UserData.sharedInstance.save(walletMnemonic: mnemonic)
        
        let seed = Mnemonic.createSeed(mnemonic: mnemonic)
        let seed32Bytes = seed.bytes[0..<32]
        
        return seed32Bytes.hexString
    }
    
    func testCrypter() {
        let sk1 = Nonce(length: 32).description.hexEncoded
        
        var pk1: String? = nil
        do {
            pk1 = try pubkeyFromSecretKey(mySecretKey: sk1)
        } catch {
            print(error.localizedDescription)
        }
        
        guard let pk1 = pk1 else {
            self.showSuccessWithMessage("There was an error. Please try again later")
            return
        }
        
        guard let ip = hardwarePostDto.ip else {
            self.showSuccessWithMessage("There was an error. Please try again later")
            return
        }
        
        self.newMessageBubbleHelper.showLoadingWheel()
        
        let url = "\(getUrl(route: ip)):\(hardwarePostDto.port)"
        
        API.sharedInstance.getHardwarePublicKey(url: "\(url)/ecdh", callback: { pubKey in
            
            var sec1: String? = nil
            do {
                sec1 = try deriveSharedSecret(theirPubkey: pubKey, mySecretKey: sk1)
            } catch {
                print(error.localizedDescription)
            }
            
            let seed = self.generateAndPersistWalletMnemonic()
            
            self.showMnemonicToUser() {
                guard let sec1 = sec1 else {
                    self.showSuccessWithMessage("There was an error. Please try again later")
                    return
                }
                
                // encrypt plaintext with sec1
                let nonce = Nonce(length: 12).description.hexEncoded
                var cipher: String? = nil
                
                do {
                    cipher = try encrypt(plaintext: seed, secret: sec1, nonce: nonce)
                } catch {
                    print(error.localizedDescription)
                }

                guard let cipher = cipher else {
                    self.showSuccessWithMessage("There was an error. Please try again later")
                    return
                }
                
                self.hardwarePostDto.publicKey = pk1
                self.hardwarePostDto.encryptedSeed = cipher

                API.sharedInstance.sendSeedToHardware(
                    url: "\(url)/config",
                    hardwarePostDto: self.hardwarePostDto,
                    callback: { success in
                        
                    if (success) {
                        UserDefaults.Keys.setupSigningDevice.set(true)
                        
                        self.showSuccessWithMessage("Seed sent to hardware successfully")
                    } else {
                        self.showErrorWithMessage("Error sending seed to hardware")
                    }
                        
                    self.endCallback()
                })
            }
            
        }, errorCallback: {
            self.showErrorWithMessage("Error getting hardware public key")
        })
    }
    
    func showMnemonicToUser(callback: @escaping () -> ()) {
        self.newMessageBubbleHelper.hideLoadingWheel()
        
        if let mnemonic = UserData.sharedInstance.getMnemonic() {
            AlertHelper.showAlert(title: "Store your Mnemonic securely", message: mnemonic, on: vc, completion: {
                callback()
            })
        }
    }
    
    func getUrl(route: String) -> String {
        if let url = URL(string: route), let _ = url.scheme {
            return url.absoluteString
        }
        return "http://\(route)"
        
    }
    
    func showErrorWithMessage(_ message: String) {
        self.newMessageBubbleHelper.hideLoadingWheel()
        
        self.newMessageBubbleHelper.showGenericMessageView(
            text: message,
            delay: 6,
            textColor: UIColor.white,
            backColor: UIColor.Sphinx.PrimaryRed,
            backAlpha: 1.0
        )
    }
    
    func showSuccessWithMessage(_ message: String) {
        self.newMessageBubbleHelper.showGenericMessageView(
            text: message,
            delay: 6,
            textColor: UIColor.white,
            backColor: UIColor.Sphinx.PrimaryGreen,
            backAlpha: 1.0
        )
    }
}

extension CrypterManager: CLLocationManagerDelegate {

    // MARK: - CLLocationManagerDelegate Methods

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let lastLocation = locations.last {
            print("<LocationManager> lastLocation:\(lastLocation.coordinate.latitude), \(lastLocation.coordinate.longitude)")
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // Detect the CLAuthorizationStatus and enable the capture of associated SSID.
        if status == CLAuthorizationStatus.authorizedAlways || status == CLAuthorizationStatus.authorizedWhenInUse  {
            setupSigningDevice()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let error = error as? CLError, error.code == .denied {
            
            print("<LocationManager> Error Denied: \(error.localizedDescription)")
            manager.stopUpdatingLocation()
            
            setupSigningDevice()
        }
    }
}