// Created by Rich Morris on 5/5/26.
// Lineup Changer
// PlayerListView.swift
//
//
//
// PlayerListView routes the Players tab to the selected sport's roster screen.
import SwiftUI

// MARK: - Player List View
// Small sport router for the Players tab.
struct PlayerListView: View {
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
                    HStack(spacing: 10) {
                        Image(systemName: "person.3.fill")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.45), radius: 2, x: 0, y: 1)

                        Text("Players")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.25), in: Capsule())
                }
            }
        }
    }
}
