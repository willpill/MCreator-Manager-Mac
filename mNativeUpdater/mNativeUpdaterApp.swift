//
//  mNativeUpdaterApp.swift
//  mNativeUpdater
//
//  Created by Yinwei Z on 10/22/23.
//

import SwiftUI

@main
struct mNativeUpdaterApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(
                  width: 880, height: 580)
                .fixedSize()
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowResizability(.contentSize)
    }
    
}

    
