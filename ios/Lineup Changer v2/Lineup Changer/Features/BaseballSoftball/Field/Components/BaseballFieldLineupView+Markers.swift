// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BaseballFieldLineupView+Markers.swift
//
//
//
import SwiftUI

// MARK: - Baseball Field Lineup Markers
extension BaseballFieldLineupView {
    // MARK: - Position Marker Factory
    // Creates a configured marker for one position at a specific proportional field point.
    // The helper calculates player data, visual state, safe placement, and tap behavior.
    func positionMarker(_ position: FieldPosition, at point: CGPoint, fieldSize: CGSize) -> some View {
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
