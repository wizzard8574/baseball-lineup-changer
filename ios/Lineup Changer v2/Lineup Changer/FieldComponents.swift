// Created by Rich Morris on 5/5/26.
// Lineup Changer
// FieldComponents.swift
//
//
//
// FieldComponents.swift contains reusable SwiftUI pieces for drawing the baseball field
// preview and placing interactive player markers over each defensive position.
import SwiftUI

// MARK: - Field Preview View
// Displays the baseball field image with the current lineup layered on top.
// The parent view provides the lineup data and handles taps on individual positions.
struct FieldPreviewView: View {
    // Maps each defensive field position to the player assigned there.
    let lineup: [FieldPosition: Player]
    // Controls whether position rating chips appear under assigned players.
    let showRatings: Bool
    // Controls whether markers show full names or compact first-name labels.
    let showFullNameAndNumber: Bool
    // Callback fired when the user taps a position marker.
    let onPositionTap: (FieldPosition) -> Void

    // Keeps the field preview square so the image and overlay markers stay aligned.
    var body: some View {
        GeometryReader { proxy in
            // Use the smaller dimension so the field remains a perfect square.
            let side = min(proxy.size.width, proxy.size.height)

            ZStack {
                // Static baseball field artwork.
                Image("baseball_field_clean")
                    .resizable()
                    .scaledToFit()
                    .frame(width: side, height: side)

                // Interactive lineup overlay positioned over the field image.
                BaseballFieldLineupView(
                    lineup: lineup,
                    showRatings: showRatings,
                    showFullNameAndNumber: showFullNameAndNumber,
                    onPositionTap: onPositionTap
                )
                .frame(width: side, height: side)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

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
// MARK: - Baseball Field Lineup Overlay
// Interactive overlay that positions a marker for every baseball/softball field position.
// Marker coordinates are proportional to the available field size so the overlay scales
// with the field image.
struct BaseballFieldLineupView: View {
    // Current field assignments keyed by defensive position.
    let lineup: [FieldPosition: Player]
    // Controls whether player position ratings are displayed on markers.
    let showRatings: Bool
    // Controls compact versus full marker name formatting.
    let showFullNameAndNumber: Bool
    // Optional tap handler used by parent screens to open assignment controls.
    var onPositionTap: ((FieldPosition) -> Void)? = nil
    // Turns on the marker entrance animation after the overlay appears.
    @State private var hasAppeared = false
    // Tracks the last tapped marker so it can be highlighted above the others.
    @State private var selectedPosition: FieldPosition?

    // Places all position markers over the field using proportional coordinates.
    var body: some View {
        GeometryReader { geometry in
            // Current overlay size used to convert proportional marker coordinates to points.
            let width = geometry.size.width
            let height = geometry.size.height

            ZStack {
                // Outfield positions.
                positionMarker(.centerField, at: CGPoint(x: width * 0.47, y: height * 0.13), fieldSize: geometry.size)
                positionMarker(.leftField, at: CGPoint(x: width * 0.17, y: height * 0.29), fieldSize: geometry.size)
                positionMarker(.rightField, at: CGPoint(x: width * 0.77, y: height * 0.29), fieldSize: geometry.size)
                // Middle infield positions.
                positionMarker(.shortstop, at: CGPoint(x: width * 0.35, y: height * 0.47), fieldSize: geometry.size)
                positionMarker(.secondBase, at: CGPoint(x: width * 0.60, y: height * 0.47), fieldSize: geometry.size)
                // Corner infield positions.
                positionMarker(.thirdBase, at: CGPoint(x: width * 0.28, y: height * 0.64), fieldSize: geometry.size)
                positionMarker(.firstBase, at: CGPoint(x: width * 0.67, y: height * 0.64), fieldSize: geometry.size)
                // Battery positions are anchored lower on the field preview.
                positionMarker(.pitcher, at: CGPoint(x: width * 0.12, y: height * 0.82), fieldSize: geometry.size)
                positionMarker(.catcher, at: CGPoint(x: width * 0.76, y: height * 0.82), fieldSize: geometry.size)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .animation(.easeInOut(duration: 0.25), value: lineup)
            .onAppear {
                // Animate markers into place after the field overlay appears.
                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                    hasAppeared = true
                }
            }
        }
    }

    // MARK: - Position Marker Factory
    // Creates a configured marker for one position at a specific proportional field point.
    // The helper calculates player data, visual state, safe placement, and tap behavior.
    private func positionMarker(_ position: FieldPosition, at point: CGPoint, fieldSize: CGSize) -> some View {
        // Pull the assigned player and their rating for this specific position.
        let player = lineup[position]
        let rating = player?.positionRatings[position]
        // Precompute marker display state used by PositionMarkerView.
        let positionText = label(for: position)
        let isAssigned = player != nil
        let accentColor = markerAccentColor(rating: rating, isAssigned: isAssigned)
        let isLowRating = rating.map { $0 <= 3 } ?? false
        let isSelected = selectedPosition == position
        // Rating chips make the marker taller, so reserve extra height when shown.
        let markerHeight: CGFloat = showRatings && rating != nil ? 82 : 58

        // Render the marker and attach placement, animation, tap, and layering behavior.
        return PositionMarkerView(
            position: position,
            player: player,
            rating: rating,
            positionText: positionText,
            isAssigned: isAssigned,
            accentColor: accentColor,
            isLowRating: isLowRating,
            isSelected: isSelected,
            showRatings: showRatings,
            showFullNameAndNumber: showFullNameAndNumber,
            hasAppeared: hasAppeared
        )
        .frame(width: markerWidth(for: position), height: markerHeight)
        .contentShape(Rectangle())
        .offset(labelOffset(for: position, point: point, in: fieldSize, markerWidth: markerWidth(for: position)))
        .position(edgeSafePoint(for: position, point: point, fieldSize: fieldSize))
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: player?.id)
        .animation(.easeInOut(duration: 0.2), value: rating)
        .onTapGesture {
            // Highlight this marker locally before notifying the parent view.
            selectedPosition = position
            onPositionTap?(position)
        }
        .zIndex(isSelected ? 1000 : 0)
    }

    // MARK: - Overlay Helpers
    // Chooses marker color based on assignment and rating.
    // Unassigned positions are gray, unrated assigned positions are blue,
    // and rated positions shift color by rating threshold.
    private func markerAccentColor(rating: Int?, isAssigned: Bool) -> Color {
        guard isAssigned else { return Color.gray }

        guard let rating else { return Color.blue }

        if rating <= 2 {
            return Color.blue
        } else if rating <= 3 {
            return Color.yellow
        } else {
            return Color.red
        }
    }

    // Returns the marker width used by the overlay's positioning calculations.
    private func markerWidth(for position: FieldPosition) -> CGFloat {
        switch position {
        case .pitcher, .catcher:
            return 132
        default:
            return 96
        }
    }

    // Nudges labels inward near the left and right field edges so they remain visible.
    private func labelOffset(for position: FieldPosition, point: CGPoint, in fieldSize: CGSize, markerWidth: CGFloat) -> CGSize {
        // Keep pitcher/catcher labels anchored at the corners so they do not slide inward over home plate.
        if position == .pitcher || position == .catcher {
            return .zero
        }

        let edgeZone = fieldSize.width * 0.28
        let shift = markerWidth * 0.28

        if point.x < edgeZone {
            return CGSize(width: shift, height: 0)
        }

        if point.x > fieldSize.width - edgeZone {
            return CGSize(width: -shift, height: 0)
        }

        return .zero
    }

    // Clamps marker coordinates inside the visible field area so labels are not clipped.
    private func edgeSafePoint(for position: FieldPosition, point: CGPoint, fieldSize: CGSize) -> CGPoint {
        // Calculate safe bounds using marker size plus additional visual padding.
        let markerHalfWidth = markerWidth(for: position) / 2
        let horizontalPadding: CGFloat = 8
        let verticalPadding: CGFloat = 34
        let markerHalfHeight: CGFloat = showRatings ? 38 : 28

        let minX = markerHalfWidth + horizontalPadding
        let maxX = fieldSize.width - markerHalfWidth - horizontalPadding

        let minY = markerHalfHeight + verticalPadding
        let maxY = fieldSize.height - markerHalfHeight - verticalPadding

        // Clamp the requested point into the safe rectangular bounds.
        let safeX = min(max(point.x, minX), maxX)
        let safeY = min(max(point.y, minY), maxY)

        return CGPoint(x: safeX, y: safeY)
    }

    // Uses the FieldPosition raw value as the short marker label.
    private func label(for position: FieldPosition) -> String {
        position.rawValue
    }
}
