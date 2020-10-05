//
//  CoreBluetoothBeacon_ReduxApp.swift
//  Shared
//
//  Created by Nicolas Philippe on 10/5/20.
//

import SwiftUI
import SwiftRex
import CombineRex
import CombineRextensions

@main
struct CoreBluetoothBeacon_ReduxApp: App {
    
    @StateObject var store = World
        .origin
        .store()
        .asObservableViewModel(initialState: .empty)
    
    var body: some Scene {
        WindowGroup {
            ViewProducer.content(store: store).view()
        }
    }
}
