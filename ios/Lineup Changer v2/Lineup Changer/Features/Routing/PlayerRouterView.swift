// Created by Rich Morris on 5/5/26.
// Lineup Changer
// PlayerListView.swift
//
//
//
// PlayerListView routes the Players tab to the selected sport's roster screen.
import SwiftUI

// MARK: - Player Router View
// Small sport router for the Players tab.
struct PlayerRouterView: View {
    // Shared roster, coach, team, and sport state.
    @ObservedObject var viewModel: LineupViewModel

    // MARK: - Body
    // Shows the selected sport's roster UI or a placeholder for unsupported sports.
    var body: some View {
        switch viewModel.selectedSport {
        case .baseballSoftball:
            BaseballPlayersView(viewModel: viewModel)
        case .basketball:
            BasketballPlayersView(viewModel: viewModel)
        default:
            comingSoonView
        }
    }

    // MARK: - Coming Soon Placeholder
    // Placeholder screen shown for sports whose roster features are not yet implemented.
    private var comingSoonView: some View {
        NavigationStack {
            ZStack {
                AppSportsBackground()

                VStack(spacing: 16) {
                    Image(systemName: "person.3")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)

                    Text("\(viewModel.selectedSport.rawValue) Players Coming Soon")
                        .font(.headline)

                    Text("Player setup for this sport will be available in a future update.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    AppToolbarTitle(title: "Players", systemImage: "person.3.fill")
                }
            }
        }
    }
}
