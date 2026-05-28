//
//  KiezioApp.swift
//  Kiezio
//
//  Created by Dennis Dachkovski on 10.05.26.
//

import SwiftUI

@main
struct KiezioApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                #if DEBUG
                .task {
                    await MVPSelfCheck.runIfRequested()
                }
                #endif
        }
    }
}
