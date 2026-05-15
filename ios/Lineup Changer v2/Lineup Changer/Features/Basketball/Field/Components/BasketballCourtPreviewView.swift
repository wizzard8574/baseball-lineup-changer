// Created by Rich Morris on 5/15/26.
// Lineup Changer
// BasketballCourtPreviewView.swift
//
//
//
import SwiftUI

// MARK: - Basketball Court Preview View
struct BasketballCourtPreviewView: View {
    let lineup: [BasketballPosition: Player]
    let showRatings: Bool
    let showFullNameAndNumber: Bool
    let onPositionTap: (BasketballPosition) -> Void

    var body: some View {
        Color.clear
            .aspectRatio(courtImageAspectRatio, contentMode: .fit)
            .background {
                Image("BBallCourtView")
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(courtImageCropScale)
            }
            .clipped()
            .overlay {
                GeometryReader { proxy in
                    markerOverlay(width: proxy.size.width, height: proxy.size.height)
                }
            }
    }

    private func markerOverlay(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            courtPositionMarker(.one, at: CGPoint(x: width * 0.23, y: height * 0.63), fieldSize: CGSize(width: width, height: height))
            courtPositionMarker(.two, at: CGPoint(x: width * 0.77, y: height * 0.63), fieldSize: CGSize(width: width, height: height))
            courtPositionMarker(.three, at: CGPoint(x: width * 0.18, y: height * 0.31), fieldSize: CGSize(width: width, height: height))
            courtPositionMarker(.four, at: CGPoint(x: width * 0.82, y: height * 0.31), fieldSize: CGSize(width: width, height: height))
            courtPositionMarker(.five, at: CGPoint(x: width * 0.50, y: height * 0.31), fieldSize: CGSize(width: width, height: height))
        }
    }

    private func courtPositionMarker(_ position: BasketballPosition, at point: CGPoint, fieldSize: CGSize) -> some View {
        let displayPoint = displayPoint(for: point, fieldSize: fieldSize)

        return BasketballCourtPositionMarkerView(
            position: position,
            player: lineup[position],
            showRatings: showRatings,
            showFullNameAndNumber: showFullNameAndNumber
        )
        .position(displayPoint)
        .onTapGesture {
            onPositionTap(position)
        }
    }

    private var courtImageAspectRatio: CGFloat {
        1314.0 / 1197.0
    }

    private var courtImageCropScale: CGFloat {
        1.055
    }

    private var croppedCoordinateInset: CGFloat {
        (courtImageCropScale - 1) / (2 * courtImageCropScale)
    }

    private func displayPoint(for imagePoint: CGPoint, fieldSize: CGSize) -> CGPoint {
        let imageLocation = CGPoint(
            x: imagePoint.x / fieldSize.width,
            y: imagePoint.y / fieldSize.height
        )
        let visibleRange = 1 - (croppedCoordinateInset * 2)
        let displayLocation = CGPoint(
            x: (imageLocation.x - croppedCoordinateInset) / visibleRange,
            y: (imageLocation.y - croppedCoordinateInset) / visibleRange
        )

        return CGPoint(
            x: fieldSize.width * displayLocation.x,
            y: fieldSize.height * displayLocation.y
        )
    }
}

// MARK: - Basketball Court Position Marker View
private struct BasketballCourtPositionMarkerView: View {
    let position: BasketballPosition
    let player: Player?
    let showRatings: Bool
    let showFullNameAndNumber: Bool

    var body: some View {
        let rating = player?.basketballPositionRatings[position]
        let accentColor = markerAccentColor(rating: rating, isAssigned: player != nil)

        ZStack {
            Circle()
                .fill(Color.white.opacity(player == nil ? 0.14 : 0.22))
                .frame(width: 5, height: 5)
                .shadow(color: accentColor.opacity(player == nil ? 0.25 : 0.60), radius: player == nil ? 2 : 7)

            VStack(spacing: 3) {
                Text(position.lineupBubbleLabel)
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.65)
                    .lineLimit(1)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(accentColor.opacity(player == nil ? 0.72 : 0.95), in: Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.75), lineWidth: 1)
                    )
                    .shadow(color: accentColor.opacity(player == nil ? 0.25 : 0.45), radius: 5, x: 0, y: 2)

                Text(player.map {
                    PlayerDisplayHelper.displayLabel(
                        for: $0,
                        showFullNameAndNumber: showFullNameAndNumber,
                        includeStatus: false
                    )
                } ?? "Open")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color(uiColor: .label))
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .frame(width: 86)
                .background(Color(uiColor: .systemBackground).opacity(player == nil ? 0.66 : 0.82))
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(accentColor.opacity(player == nil ? 0.22 : 0.55), lineWidth: 1)
                )

                if showRatings {
                    Text(ratingText)
                        .font(.caption2)
                        .foregroundStyle(ratingTextColor(for: rating))
                        .lineLimit(1)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(ratingBackgroundColor(for: rating, accentColor: accentColor))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(accentColor.opacity(player == nil ? 0.20 : 0.45), lineWidth: 1)
                        )
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(accentColor.opacity(player == nil ? 0.05 : 0.16))
                    .blur(radius: 0.5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(accentColor.opacity(player == nil ? 0.18 : 0.34), lineWidth: 1)
            )
            .shadow(color: accentColor.opacity(player == nil ? 0.08 : 0.36), radius: player == nil ? 2 : 8, x: 0, y: 3)
        }
        .frame(width: 94)
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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

    private var ratingText: String {
        guard let player else { return "Unassigned" }
        guard let rating = player.basketballPositionRatings[position] else { return "No rating" }
        return "Rating \(rating)"
    }

    private func ratingTextColor(for rating: Int?) -> Color {
        guard let rating else { return .secondary }
        return rating >= 4 ? .black : .white
    }

    private func ratingBackgroundColor(for rating: Int?, accentColor: Color) -> Color {
        guard rating != nil else {
            return Color(uiColor: .systemBackground).opacity(0.62)
        }

        return accentColor.opacity(0.28)
    }
}
