// Created by Rich Morris on 5/15/26.
// Lineup Changer
// BasketballCourtView+ScreenChrome.swift
//
//
//
import SwiftUI

// MARK: - Basketball Court Screen Chrome
extension BasketballCourtView {
    var basketballCourtScreen: some View {
        NavigationStack {
            ZStack {
                AppSportsBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        basketballCourtSections
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 10)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    AppToolbarTitle(title: "Court", systemImage: "basketball.fill")
                }
            }
            .confirmationDialog(
                selectedCourtPosition.map { "Choose Player for \($0.lineupBubbleLabel)" } ?? "Choose Player",
                isPresented: $isShowingCourtPositionPlayerPicker,
                titleVisibility: .visible
            ) {
                if let selectedCourtPosition {
                    Button("Unassigned") {
                        updateBasketballCourtPosition(selectedCourtPosition, playerID: nil)
                    }

                    ForEach(basketballCourtPickerPlayers(for: selectedCourtPosition)) { player in
                        Button(basketballCourtDisplayLabel(for: player)) {
                            updateBasketballCourtPosition(selectedCourtPosition, playerID: player.id)
                        }
                    }
                }

                Button("Cancel", role: .cancel) { }
            }
            .onAppear {
                viewModel.syncBasketballLineup(autoAssignIfDefaultOrder: true)
                viewModel.syncBasketballCourtLineupsWithRoster()
                selectedBasketballPeriod = min(selectedBasketballPeriod, viewModel.basketballPeriodFormat.periodCount)
            }
            .onChange(of: viewModel.basketballPeriodFormat) { _, newValue in
                selectedBasketballPeriod = min(selectedBasketballPeriod, newValue.periodCount)
            }
        }
    }
}
