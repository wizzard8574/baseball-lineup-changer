// Created by Rich Morris on 5/5/26.
// Lineup Changer
// ContentView+Tabs.swift
//
//
//
import SwiftUI

extension ContentView {
    var mainTabView: some View {
        TabView(selection: $selectedTab) {
            fieldTab
            lineupTab
            playersTab
            notesTab
            settingsTab
        }
        .onAppear(perform: selectInitialTab)
    }

    var fieldTab: some View {
        FieldRouterView(viewModel: viewModel)
            .tabItem {
                tabLabel(for: .field)
            }
            .tag(MainTab.field)
    }

    var lineupTab: some View {
        LineupRouterView(viewModel: viewModel)
            .tabItem {
                tabLabel(for: .lineup)
            }
            .tag(MainTab.lineup)
    }

    var playersTab: some View {
        PlayerRouterView(viewModel: viewModel)
            .tabItem {
                tabLabel(for: .players)
            }
            .tag(MainTab.players)
    }

    var notesTab: some View {
        NotesView(viewModel: viewModel)
            .tabItem {
                tabLabel(for: .notes)
            }
            .tag(MainTab.notes)
    }

    var settingsTab: some View {
        SettingsView(viewModel: viewModel)
            .tabItem {
                tabLabel(for: .settings)
            }
            .tag(MainTab.settings)
    }

    func tabLabel(for tab: MainTab) -> Label<Text, Image> {
        Label(
            tab.title(for: viewModel.selectedSport),
            systemImage: tab.iconName(for: viewModel.selectedSport)
        )
    }

    func selectInitialTab() {
        // On first use with no players, start on Players so the user can build a roster.
        selectedTab = viewModel.players.isEmpty ? .players : .field
    }
}
