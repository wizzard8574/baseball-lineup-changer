// Created by Rich Morris on 5/11/26.
// Lineup Changer
// SportFeaturePlaceholderView.swift
//
//
//
import SwiftUI

// MARK: - Sport Feature Placeholder View
struct SportFeaturePlaceholderView: View {
    let title: String
    let message: String
    let toolbarTitle: String
    let toolbarIconName: String
    let symbolName: String

    var body: some View {
        NavigationStack {
            ZStack {
                AppSportsBackground()

                VStack(spacing: 16) {
                    Image(systemName: symbolName)
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)

                    Text(title)
                        .font(.headline)

                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    AppToolbarTitle(title: toolbarTitle, systemImage: toolbarIconName)
                }
            }
        }
    }
}
