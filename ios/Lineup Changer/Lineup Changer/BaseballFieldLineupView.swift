//
//  BaseballFieldLineupView.swift
//  Lineup Changer
//
//  Created by Rich Morris on 5/3/26.
//

import SwiftUI

struct BaseballFieldLineupView: View {
    let lineup: [FieldPosition: Player]
    let showRatings: Bool
    let showFullNameAndNumber: Bool
    var onPositionTap: ((FieldPosition) -> Void)? = nil
    @State private var hasAppeared = false
    @State private var selectedPosition: FieldPosition?

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            ZStack {
                positionMarker(.centerField, at: CGPoint(x: width * 0.47, y: height * 0.13), fieldSize: geometry.size)
                positionMarker(.leftField, at: CGPoint(x: width * 0.17, y: height * 0.29), fieldSize: geometry.size)
                positionMarker(.rightField, at: CGPoint(x: width * 0.77, y: height * 0.29), fieldSize: geometry.size)
                positionMarker(.shortstop, at: CGPoint(x: width * 0.35, y: height * 0.47), fieldSize: geometry.size)
                positionMarker(.secondBase, at: CGPoint(x: width * 0.60, y: height * 0.47), fieldSize: geometry.size)
                positionMarker(.thirdBase, at: CGPoint(x: width * 0.28, y: height * 0.64), fieldSize: geometry.size)
                positionMarker(.firstBase, at: CGPoint(x: width * 0.67, y: height * 0.64), fieldSize: geometry.size)
                positionMarker(.pitcher, at: CGPoint(x: width * 0.12, y: height * 0.82), fieldSize: geometry.size)
                positionMarker(.catcher, at: CGPoint(x: width * 0.76, y: height * 0.82), fieldSize: geometry.size)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .animation(.easeInOut(duration: 0.25), value: lineup)
            .onAppear {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                    hasAppeared = true
                }
            }
        }
    }

    private func positionMarker(_ position: FieldPosition, at point: CGPoint, fieldSize: CGSize) -> some View {
        let player = lineup[position]
        let rating = player?.positionRatings[position]
        let positionText = label(for: position)
        let isAssigned = player != nil
        let accentColor = markerAccentColor(rating: rating, isAssigned: isAssigned)
        let isLowRating = rating.map { $0 <= 3 } ?? false
        let isSelected = selectedPosition == position
        let markerHeight: CGFloat = showRatings && rating != nil ? 82 : 58

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
            selectedPosition = position
            onPositionTap?(position)
        }
        .zIndex(isSelected ? 1000 : 0)
    }

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

    private func markerWidth(for position: FieldPosition) -> CGFloat {
        switch position {
        case .pitcher, .catcher:
            return 132
        default:
            return 96
        }
    }

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

    private func edgeSafePoint(for position: FieldPosition, point: CGPoint, fieldSize: CGSize) -> CGPoint {
        let markerHalfWidth = markerWidth(for: position) / 2
        let horizontalPadding: CGFloat = 8
        let verticalPadding: CGFloat = 34
        let markerHalfHeight: CGFloat = showRatings ? 38 : 28

        let minX = markerHalfWidth + horizontalPadding
        let maxX = fieldSize.width - markerHalfWidth - horizontalPadding

        let minY = markerHalfHeight + verticalPadding
        let maxY = fieldSize.height - markerHalfHeight - verticalPadding

        let safeX = min(max(point.x, minX), maxX)
        let safeY = min(max(point.y, minY), maxY)

        return CGPoint(x: safeX, y: safeY)
    }

    private func label(for position: FieldPosition) -> String {
        position.rawValue
    }
}
