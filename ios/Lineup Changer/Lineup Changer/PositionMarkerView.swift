//
//  PositionMarkerView.swift
//  Lineup Changer
//
//  Created by Rich Morris on 5/4/26.
//

import SwiftUI

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
