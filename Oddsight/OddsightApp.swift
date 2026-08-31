//
//  OddsightApp.swift
//  Oddsight
//
//  Created by Emanuil Vartanyan on 8/29/26.
//

import SwiftUI

@main
struct OddsightApp: App {
    @UIApplicationDelegateAdaptor(OddsightAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
