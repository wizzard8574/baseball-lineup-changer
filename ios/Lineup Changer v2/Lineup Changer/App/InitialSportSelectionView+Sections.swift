// Created by Rich Morris on 5/5/26.
// Lineup Changer
// InitialSportSelectionView+Sections.swift
//
//
//
import SwiftUI

extension InitialSportSelectionView {
    var initialSportSelectionScreen: some View {
        GeometryReader { proxy in
            ZStack {
                // Background artwork sized to the current device dimensions.
                Image("LaunchScreen")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .ignoresSafeArea()

                // Darkens the lower portion so the sport buttons remain readable.
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.05),
                        Color.clear,
                        Color.black.opacity(0.48)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack {
                    Spacer()

                    // Sport choices are grouped into one pill-shaped control bar.
                    sportButtonBar
                        .padding(.bottom, max(proxy.safeAreaInsets.bottom + 18, 34))
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .zIndex(10)
            }
        }
    }

    var sportButtonBar: some View {
        HStack(spacing: 10) {
            ForEach(SportType.allCases) { sport in
                sportButton(sport)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.black.opacity(0.72), in: Capsule())
        .overlay(
            Capsule()
                .stroke(.white.opacity(0.55), lineWidth: 1.2)
        )
        .shadow(color: .black.opacity(0.85), radius: 28, x: 0, y: 12)
    }
}
