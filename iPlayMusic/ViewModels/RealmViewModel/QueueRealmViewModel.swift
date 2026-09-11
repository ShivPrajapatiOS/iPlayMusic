//
//  QueueRealmViewModel.swift
//  iPlayMusic
//
//  Created by Shiv on 10/09/26.
//

import Foundation
import RealmSwift
import Combine

class QueueRealmViewModel: ObservableObject {
    static let shared = QueueRealmViewModel()
    
    private var realm: Realm? {
        try? Realm(configuration: SharedRealm.getSharedRealmConfiguration())
    }
    
    private init() {}
    
    func saveQueue(_ songs: [SongModel]) {
        guard let realm = self.realm else { return }
        
        do {
            try realm.write {
                // Purani poori queue delete karo
                let existing = realm.objects(QueueSongRealmModel.self)
                realm.delete(existing)
                
                // Naye songs order ke saath add karo
                for (index, song) in songs.enumerated() {
                    guard let jsonString = song.toJSONString() else { continue }
                    
                    let queueItem = QueueSongRealmModel()
                    queueItem.song_id = song.id
                    queueItem.order = index
                    queueItem.songDataJSON = jsonString
                    realm.add(queueItem)
                }
            }
        } catch {
            print("❌ QueueRealmViewModel saveQueue error: \(error.localizedDescription)")
        }
    }
    
    func loadQueue() -> [SongModel] {
        guard let realm = self.realm else { return [] }
        
        let items = realm.objects(QueueSongRealmModel.self).sorted(byKeyPath: "order", ascending: true)
        
        return items.compactMap { item in
            guard let jsonData = item.songDataJSON.data(using: .utf8) else { return nil }
            return try? JSONDecoder().decode(SongModel.self, from: jsonData)
        }
    }
    
    func removeSong(songId: String) {
        guard let realm = self.realm else { return }
        do {
            try realm.write {
                let toDelete = realm.objects(QueueSongRealmModel.self).filter("song_id == %@", songId)
                realm.delete(toDelete)
                
                // Baaki songs ka order re-adjust karo (gaps na rahe)
                let remaining = realm.objects(QueueSongRealmModel.self).sorted(byKeyPath: "order", ascending: true)
                for (index, item) in remaining.enumerated() {
                    item.order = index
                }
            }
        } catch {
            print("❌ QueueRealmViewModel removeSong error: \(error.localizedDescription)")
        }
    }
    
    func clearQueue() {
        guard let realm = self.realm else { return }
        
        do {
            try realm.write {
                let all = realm.objects(QueueSongRealmModel.self)
                realm.delete(all)
            }
        } catch {
            print("❌ QueueRealmViewModel clearQueue error: \(error.localizedDescription)")
        }
    }
}
