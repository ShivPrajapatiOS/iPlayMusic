//
//  RemoteConfigResponse.swift
//  iPlayMusic
//
//  Created by Shiv on 31/07/26.
//

import Foundation
import FirebaseRemoteConfig

class RemoteConfigResponse{
    
    class func getResponse(completion: @escaping()->Void) {
        
        if #available(iOS 16, macOS 15.0, *) {
            if Locale.current.region?.identifier == "CN"{
                completion()
            }
        } else {
            if Locale.current.regionCode == "CN" {
                completion()
            }
        }
        //set default value to userDefaults if value is nil
        let userDefaults = UserDefaults.standard
        userDefaults.register(
            defaults: [
                "isReview": UserDefaults.inReview,
                "closeDelay": UserDefaults.closeDelay,
            ]
        )
        
        let remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        #if DEBUG
        settings.minimumFetchInterval = 0
        #else
        settings.minimumFetchInterval = 0
        #endif
        
        remoteConfig.configSettings = settings
        remoteConfig.setDefaults([
            "inReview": UserDefaults.inReview as NSObject,
            "closeDelay": UserDefaults.closeDelay as NSObject,
        ])
        
        remoteConfig.fetch { status, error in
            switch status{
            case .success:
                remoteConfig.activate { changed, error in
                    UserDefaults.inReview = remoteConfig.configValue(forKey: "inReview").boolValue
                    UserDefaults.closeDelay = Int(truncating: remoteConfig.configValue(forKey: "closeDelay").numberValue)
                }
                break
            case .failure:
                break
            default:
                break
            }
            completion()
        }
    }
}
