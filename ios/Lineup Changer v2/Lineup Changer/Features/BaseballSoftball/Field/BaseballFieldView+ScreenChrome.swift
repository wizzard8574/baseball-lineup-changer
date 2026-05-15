// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BaseballFieldView+ScreenChrome.swift
//
//
//
import SwiftUI

// MARK: - Screen Chrome
extension BaseballFieldView {
    var fieldScreen: some View {
        NavigationStack {
            ZStack {
                AppSportsBackground()

                Form {
                    fieldFormSections
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    AppToolbarTitle(title: "Field", systemImage: "baseball.fill")
                }
            }
            .onAppear {
                viewModel.syncBaseballFieldAssignmentsToLineupBattersIfNeeded()
            }
        }
    }
}
