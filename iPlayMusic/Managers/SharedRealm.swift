//
//  SharedRealm.swift
//  iPlayMusic
//
//  Created by Shiv on 05/08/26.
//

import Foundation
import SwiftUI
import Combine
import Realm
import RealmSwift

// MARK: - Shared Realm Configuration Data Base Access
enum SharedRealm {
    static func getSharedRealmConfiguration() -> Realm.Configuration {
        let userId = StateManager.shared.uid
        guard let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupID) else {
            fatalError("App Group Container URL Not Found")
        }
        
        let fileName = userId.isEmpty ? "todo_default.realm" : "todo_shared_data_\(userId).realm"
        
        let realmURL = containerURL.appendingPathComponent(fileName)
        print("Recommended Shared Realm Path (App Group): \(realmURL)")
        
        let config = Realm.Configuration(fileURL: realmURL, schemaVersion: 8, migrationBlock: { migration, oldSchemaVersion in
                print(migration.oldSchema)
                print(migration.newSchema)
                print(oldSchemaVersion)
            }
        )
        return config
    }
    
    static func deleteSharedRealmFile() {
        // Close all Realm instances
        let userId = StateManager.shared.uid
        guard let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupID) else {
            print("❌ App Group container not found")
            return
        }
        let fileName = userId.isEmpty ? "todo_default.realm" : "todo_shared_data_\(userId).realm"
        let realmURL = containerURL.appendingPathComponent(fileName)
        do {
            if FileManager.default.fileExists(atPath: realmURL.path) {
                try FileManager.default.removeItem(at: realmURL)
                print("✅ Realm file deleted successfully")
            } else {
                print("⚠️ Realm file does not exist")
            }
        } catch {
            print("❌ Failed to delete realm file:", error.localizedDescription)
        }
    }
}

