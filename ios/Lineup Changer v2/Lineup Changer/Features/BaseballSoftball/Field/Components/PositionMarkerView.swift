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

    // MARK: - Marker Subviews
    // Builds the circular position badge with gradient, outline, glow, and selection styling.
    private var positionBadge: some View {
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

    // MARK: - Marker Helpers
    // Pitcher and catcher markers need extra width because their labels sit near field edges.
    private var markerWidth: CGFloat {
        switch position {
        case .pitcher, .catcher:
            return 132
        default:
            return 96
        }
    }

    // Chooses text color for rating chips based on the rating range.
    private func ratingTextColor(for rating: Int) -> Color {
        if rating <= 2 {
            return .white
        } else if rating <= 3 {
            return .white
        } else {
            return .black
        }
    }

    // Builds the player label shown below the position badge.
    // Empty positions show an em dash; assigned positions show either compact or full labels.
    private var playerLabel: String {
        // Empty positions show a placeholder instead of a player name.
        guard let player else { return "—" }

        // Split the name so compact mode can show only the first name.
        let nameParts = player.name.split(separator: " ").map(String.init)

        // Include jersey number when present.
        if showFullNameAndNumber {
            return player.number.isEmpty ? player.name : "#\(player.number) \(player.name)"
        } else {
            let firstName = nameParts.first ?? player.name
            return player.number.isEmpty ? firstName : "#\(player.number) \(firstName)"
        }
    }
}
