//
//  ContentView.swift
//  Lineup Changer Catchercom
//
//  Created by Rich Morris on 5/16/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var audio = CatcherAudioManager()
    @State private var showCallsTab = true
    @State private var showPlaysTab = true
    @State private var showMessageTab = true

    var body: some View {
        ZStack {
            AppBackgroundView()

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

                HistoryView(audio: audio)
                    .tabItem {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }

                SettingsView(
                    showCallsTab: $showCallsTab,
                    showPlaysTab: $showPlaysTab,
                    showMessageTab: $showMessageTab
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
