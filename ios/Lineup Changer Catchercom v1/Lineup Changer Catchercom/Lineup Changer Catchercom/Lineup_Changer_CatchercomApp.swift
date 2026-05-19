//
//  Lineup_Changer_CatchercomApp.swift
//  Lineup Changer Catchercom
//
//  Created by Rich Morris on 5/16/26.
//

import SwiftUI
import UIKit

@main
struct Lineup_Changer_CatchercomApp: App {
    // MARK: - Scene State

    @Environment(\.scenePhase) private var scenePhase

    // MARK: - App Entry

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Keep the phone awake while the app is open so a coach does not have to unlock mid-game.
                    UIApplication.shared.isIdleTimerDisabled = true
                }
                .onChange(of: scenePhase) { _, newPhase in
                    // Only hold the idle timer while this app is active; let iOS behave normally in the background.
                    UIApplication.shared.isIdleTimerDisabled = newPhase == .active
                }
        }
    }
}
