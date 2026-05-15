// Created by Rich Morris on 5/15/26.
// Lineup Changer
// BasketballCourtView+Helpers.swift
//
//
//
import SwiftUI

// MARK: - Basketball Court Helpers
extension BasketballCourtView {
    var basketballCourtLineup: [BasketballPosition: Player] {
        viewModel.basketballCourtLineup(for: selectedBasketballPeriod)
    }

    func basketballCourtGroupedSection<Content: View>(
        _ title: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                basketballCourtSectionHeader(title)
                    .padding(.leading, 20)
            }

            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func basketballCourtSectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .textCase(nil)
            .shadow(color: .black.opacity(0.45), radius: 2, x: 0, y: 1)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.black.opacity(0.22), in: Capsule())
    }

    func basketballCourtDisplayLabel(for player: Player) -> String {
        PlayerDisplayHelper.displayLabel(
            for: player,
            showFullNameAndNumber: viewModel.showFullNameAndNumberInBasketball
        )
    }

    func basketballCourtRatingLabel(for player: Player, at position: BasketballPosition) -> String {
        guard let rating = player.basketballPositionRatings[position] else {
            return "No rating"
        }

        return "Rating \(rating)"
    }

    func basketballCourtPickerPlayers(for position: BasketballPosition) -> [Player] {
        let currentPlayerID = viewModel.basketballCourtPlayer(for: position, period: selectedBasketballPeriod)?.id
        let assignedPlayerIDs = Set(BasketballPosition.allCases.compactMap { assignedPosition in
            assignedPosition == position ? nil : viewModel.basketballCourtPlayer(for: assignedPosition, period: selectedBasketballPeriod)?.id
        })

        return viewModel.basketballLineupPlayers.filter { player in
            player.id == currentPlayerID || !assignedPlayerIDs.contains(player.id)
        }
    }

    func updateBasketballCourtPosition(_ position: BasketballPosition, playerID: UUID?) {
        viewModel.updateBasketballCourtPosition(position, playerID: playerID, period: selectedBasketballPeriod)
    }

    func putBasketballBenchPlayerOnCourt(_ player: Player) {
        let ratedPositions = BasketballPosition.allCases.compactMap { position -> (position: BasketballPosition, rating: Int)? in
            guard let rating = player.basketballPositionRatings[position] else { return nil }
            return (position, rating)
        }

        guard let bestPosition = ratedPositions.min(by: { lhs, rhs in
            lhs.rating < rhs.rating
        })?.position else {
            basketballCourtBenchPlacementWarningText = "Unable to put player on court without rating"
            return
        }

        basketballCourtBenchPlacementWarningText = nil
        updateBasketballCourtPosition(bestPosition, playerID: player.id)
    }
}

extension BasketballPeriodFormat {
    var courtPeriodTitle: String {
        switch self {
        case .quarters:
            return "Quarter"
        case .halves:
            return "Half"
        }
    }

    var courtPeriodPluralTitle: String {
        switch self {
        case .quarters:
            return "Quarters"
        case .halves:
            return "Halves"
        }
    }
}
