// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BaseballLineupView+ScreenChrome.swift
//
//
//
import SwiftUI

// MARK: - Baseball Lineup Screen Chrome
extension BaseballLineupView {
    var lineupScreen: some View {
        NavigationStack {
            ZStack {
                AppSportsBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        lineupFormSections
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 10)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("")
            .toolbar {
                lineupToolbar
            }
            .onAppear {
                viewModel.syncBattingOrder()
                viewModel.syncDesignatedHitterSelection()
            }
            .onChange(of: viewModel.battingOrderIDs) { _, _ in
                viewModel.syncDesignatedHitterSelection()
            }
            .sheet(isPresented: $isShowingLineupShareSheet) {
                if let lineupPDFURL {
                    ActivityView(activityItems: [lineupPDFURL])
                } else {
                    Text("No lineup grid available.")
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var lineupToolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            AppToolbarTitle(title: "Lineup", systemImage: "list.number")
        }
    }
}
