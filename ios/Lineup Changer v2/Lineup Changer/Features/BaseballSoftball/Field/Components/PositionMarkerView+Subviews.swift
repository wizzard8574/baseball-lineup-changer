// Created by Rich Morris on 5/5/26.
// Lineup Changer
// PositionMarkerView+Subviews.swift
//
//
//
import SwiftUI

// MARK: - Position Marker Subviews
extension PositionMarkerView {
    // MARK: - Marker Subviews
    // Builds the circular position badge with gradient, outline, glow, and selection styling.
    var positionBadge: some View {
        ZStack {
            // Layered circles create the badge fill, border, selected ring, and glow.
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            accentColor.opacity(0.95),
                            accentColor.opacity(0.75)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.82), lineWidth: 1.4)
                )
                .overlay(
                    Circle()
                        .stroke(accentColor.opacity(isSelected ? 0.95 : 0.55), lineWidth: isSelected ? 2.6 : 1.4)
                        .padding(2)
                )
                .overlay(
                    Circle()
                        .stroke(accentColor.opacity(isSelected ? 0.38 : 0.24), lineWidth: isSelected ? 6 : 4)
                        .blur(radius: isSelected ? 4 : 3)
                        .padding(-3)
                )
                .shadow(color: accentColor.opacity(isSelected ? 0.72 : 0.42), radius: isSelected ? 9 : 6, x: 0, y: 2)
                .shadow(color: .black.opacity(0.35), radius: 4, x: 0, y: 2)
                .animation(.easeInOut(duration: 0.22), value: accentColor)
                .animation(.spring(response: 0.28, dampingFraction: 0.72), value: isSelected)

            // Position abbreviation centered inside the badge.
            Text(positionText)
                .font(.caption.weight(.heavy))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.65)
                .lineLimit(1)
        }
        .frame(width: 22, height: 22)
    }
}
