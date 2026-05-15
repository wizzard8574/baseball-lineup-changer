// Created by Rich Morris on 5/5/26.
// Lineup Changer
// PositionMarkerView.swift
//
//
//
// PositionMarkerView renders one interactive player marker over the field image.
import SwiftUI

// MARK: - Position Marker View
// Visual marker for one defensive position on the field.
// It shows the position badge, assigned player label, optional rating, and
// selected/assigned visual states.
struct PositionMarkerView: View {
    // Defensive position represented by this marker.
    let position: FieldPosition
    // Player assigned to the position, or nil when the position is empty.
    let player: Player?
    // Player's rating for this position, when available.
    let rating: Int?
    // Short text displayed inside the circular position badge.
    let positionText: String
    // Indicates whether a player is currently assigned to this position.
    let isAssigned: Bool
    // Main color used for marker borders, shadows, and highlights.
    let accentColor: Color
    // Flags low ratings so the rating chip can receive warning styling.
    let isLowRating: Bool
    // Indicates whether this marker was the most recently tapped marker.
    let isSelected: Bool
    // Determines whether the rating chip should be rendered.
    let showRatings: Bool
    // Determines how much player name information appears in the marker label.
    let showFullNameAndNumber: Bool
    // Drives the entrance opacity/scale animation.
    let hasAppeared: Bool

    // Marker layout: subtle dot behind the visible badge/label stack.
    var body: some View {
        ZStack {
            // Small glow dot helps the marker feel anchored to the field.
            Circle()
                .fill(Color.white.opacity(isAssigned ? 0.24 : 0.14))
                .frame(width: 5, height: 5)
                .shadow(color: accentColor.opacity(isAssigned ? 0.65 : 0.25), radius: isAssigned ? 7 : 2)

            VStack(spacing: 3) {
                // Circular badge containing the defensive position abbreviation.
                positionBadge

                // Player label changes between placeholder, first name, and full name formats.
                Text(playerLabel)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                    .foregroundStyle(Color(uiColor: .label))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .frame(width: markerWidth)
                    .background(Color(uiColor: .systemBackground).opacity(isAssigned ? 0.95 : 0.82))
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(accentColor.opacity(isAssigned ? 0.65 : 0.20), lineWidth: 1)
                    )

                // Optional rating chip shown only when ratings are enabled and available.
                if showRatings, let rating {
                    Text("Rating \(rating)")
                        .font(.caption2)
                        .foregroundStyle(ratingTextColor(for: rating))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background((isLowRating ? Color.red : Color(uiColor: .systemBackground)).opacity(isLowRating ? 0.22 : 0.82))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke((isLowRating ? Color.red : accentColor).opacity(isLowRating ? 0.65 : 0.25), lineWidth: 1)
                        )
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(accentColor.opacity(isSelected ? 0.25 : (isAssigned ? 0.13 : 0.04)))
                    .blur(radius: 0.5)
            )
            .shadow(color: accentColor.opacity(isSelected ? 0.7 : (isAssigned ? 0.38 : 0.08)), radius: isSelected ? 14 : (isAssigned ? 9 : 2), x: 0, y: 3)
            .scaleEffect(isSelected ? 1.08 : (hasAppeared ? 1.0 : 0.92))
            .opacity(hasAppeared ? 1.0 : 0.0)
        }
    }
}
