//
//  ContentView.swift
//  Lineup Changer Catchercom
//
//  Created by Rich Morris on 5/16/26.
//

import SwiftUI

struct ContentView: View {
    // MARK: - Shared State

    // One audio manager is shared by every tab so the last spoken message, output route, and history stay in sync.
    @StateObject private var audio = CatcherAudioManager()

    // These settings let the user hide tabs they do not need without deleting saved calls, plays, or history.
    @AppStorage("catchercom.settings.showCallsTab") private var showCallsTab = true
    @AppStorage("catchercom.settings.showPlaysTab") private var showPlaysTab = true
    @AppStorage("catchercom.settings.showMessageTab") private var showMessageTab = true
    @AppStorage("catchercom.settings.showHistoryTab") private var showHistoryTab = true

    // MARK: - Body

    var body: some View {
        ZStack {
            AppBackgroundView()

            // Settings can hide working tabs without deleting any saved data.
            TabView {
                if showCallsTab {
                    CallsView(audio: audio)
                        .tabItem {
                            Label("Calls", systemImage: "hand.raised")
                        }
                }

                if showMessageTab {
                    CommonView(audio: audio)
                        .tabItem {
                            Label("Common", systemImage: "message")
                        }
                }

                if showPlaysTab {
                    PlaysView(audio: audio)
                        .tabItem {
                            Label("Plays", systemImage: "sportscourt")
                        }
                }

                if showHistoryTab {
                    HistoryView(audio: audio)
                        .tabItem {
                            Label("History", systemImage: "clock.arrow.circlepath")
                        }
                }

                SettingsView(
                    showCallsTab: $showCallsTab,
                    showPlaysTab: $showPlaysTab,
                    showMessageTab: $showMessageTab,
                    showHistoryTab: $showHistoryTab
                )
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
