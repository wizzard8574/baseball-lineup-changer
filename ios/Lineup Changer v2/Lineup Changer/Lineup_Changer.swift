// Created by Rich Morris on 5/5/26.
// Lineup Changer
// Lineup_Changer.swift
//
//
//
// Entry point for the Lineup Changer app.
// This file launches the shared RootView, which manages the splash screen,
// first-run setup flow, and the main application interface.
import SwiftUI

// MARK: - App Entry Point

// Main SwiftUI application object.
// SwiftUI creates this once at launch and uses it to build the app's scenes.
@main
struct Lineup_Changer: App {
    // Defines the app's primary window scene.
    var body: some Scene {
        WindowGroup {
            // RootView manages the launch flow and shared application state.
            RootView()
        }
    }
}
