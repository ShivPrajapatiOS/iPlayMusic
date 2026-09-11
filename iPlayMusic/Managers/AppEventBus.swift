//
//  AppEventBus.swift
//  iPlayMusic
//
//  Created by Shiv on 30/07/26.
//

import SwiftUI
import Combine

enum AppEvent {
    case shareCopy
    case printList
    case smartTabUncompletedTask
    case listTabUncompletedTask
    case syncData
}


final class AppEventBus {
    static let shared = AppEventBus()
    
    let publisher = PassthroughSubject<AppEvent, Never>()
    
    private init() {}
    
    func send(_ event: AppEvent) {
        publisher.send(event)
    }
}
