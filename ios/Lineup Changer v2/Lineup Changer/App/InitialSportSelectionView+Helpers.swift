// Created by Rich Morris on 5/5/26.
// Lineup Changer
// InitialSportSelectionView+Helpers.swift
//
//
//
import SwiftUI

extension InitialSportSelectionView {
    // Builds a circular sport icon button with selected/disabled visual states.
    func sportButton(_ sport: SportType) -> some View {
        Button {
            // Ignore taps on sports that are not selectable from launch yet.
            guard sport.isLaunchSelectable else { return }

            // Record selection immediately so the button can visually respond.
            selectedSport = sport

            // Brief spring animation gives the selected button a tap response.
            withAnimation(.spring(response: 0.22, dampingFraction: 0.62)) {
                selectedSport = sport
            }

            // Delay committing the selection slightly so the selection animation is visible.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                viewModel.selectSport(sport)
                onSportSelected()
            }
        } label: {
            // Emoji icon acts as the visual representation for each sport.
            Text(sport.launchSelectionIcon)
                .font(.system(size: 31))
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .fill(Color.white.opacity(selectedSport == sport ? 0.18 : 0.06))
                        )
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(selectedSport == sport ? 0.9 : 0.28), lineWidth: selectedSport == sport ? 2 : 1)
                )
                .shadow(color: .white.opacity(selectedSport == sport ? 0.45 : 0.12), radius: selectedSport == sport ? 14 : 5)
                .shadow(color: .black.opacity(0.35), radius: 7, x: 0, y: 4)
                .scaleEffect(selectedSport == sport ? 1.12 : 1.0)
                .opacity(sport.isLaunchSelectable ? 1.0 : 0.4)
        }
        .buttonStyle(.plain)
    }
}
