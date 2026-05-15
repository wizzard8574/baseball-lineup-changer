// Created by Rich Morris on 5/11/26.
// Lineup Changer
// SportSurfacePreviewView.swift
//
//
//
import SwiftUI

// MARK: - Sport Surface Preview View
struct SportSurfacePreviewView: View {
    let sport: SportType

    var body: some View {
        NavigationStack {
            ZStack {
                AppSportsBackground()

                VStack(spacing: 18) {
                    if let assetName = sport.playingSurfaceAssetName {
                        Image(assetName)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                    }

                    Text(sport.playingSurfacePlaceholderMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    AppToolbarTitle(
                        title: sport.playingSurfaceTitle,
                        systemImage: sport.playingSurfaceIconName
                    )
                }
            }
        }
    }
}
