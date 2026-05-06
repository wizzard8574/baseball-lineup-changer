//
//  FieldComponents.swift
//  Lineup Changer
//
//  Created by Rich Morris on 5/5/26.
//
import SwiftUI

// MARK: - Field Preview
struct FieldPreviewView: View {
    let lineup: [FieldPosition: Player]
    let showRatings: Bool
    let showFullNameAndNumber: Bool
    let onPositionTap: (FieldPosition) -> Void

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)

            ZStack {
                Image("baseball_field_clean")
                    .resizable()
                    .scaledToFit()
                    .frame(width: side, height: side)

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

// MARK: - Position Marker
struct PositionMarkerView: View {
    let position: FieldPosition
    let player: Player?
    let rating: Int?
    let positionText: String
    let isAssigned: Bool
    let accentColor: Color
    let isLowRating: Bool
    let isSelected: Bool
    let showRatings: Bool
    let showFullNameAndNumber: Bool
    let hasAppeared: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(isAssigned ? 0.24 : 0.14))
                .frame(width: 5, height: 5)
                .shadow(color: accentColor.opacity(isAssigned ? 0.65 : 0.25), radius: isAssigned ? 7 : 2)

            VStack(spacing: 3) {
                positionBadge

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

    private var positionBadge: some View {
        ZStack {
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

            Text(positionText)
                .font(.caption.weight(.heavy))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.65)
                .lineLimit(1)
        }
        .frame(width: 22, height: 22)
    }

    private var markerWidth: CGFloat {
        switch position {
        case .pitcher, .catcher:
            return 132
        default:
            return 96
        }
    }

    private func ratingTextColor(for rating: Int) -> Color {
        if rating <= 2 {
            return .white
        } else if rating <= 3 {
            return .white
        } else {
            return .black
        }
    }

    private var playerLabel: String {
        guard let player else { return "—" }

        let nameParts = player.name.split(separator: " ").map(String.init)

        if showFullNameAndNumber {
            return player.number.isEmpty ? player.name : "#\(player.number) \(player.name)"
        } else {
            let firstName = nameParts.first ?? player.name
            return player.number.isEmpty ? firstName : "#\(player.number) \(firstName)"
        }
    }
}
// MARK: - Baseball Field Lineup
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

