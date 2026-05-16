// Created by Rich Morris on 5/13/26.
// Lineup Changer
// BasketballLineupView+Helpers.swift
//
//
//
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Basketball Lineup Helpers
extension BasketballLineupView {
    func basketballLineupDisplayLabel(for player: Player) -> String {
        PlayerDisplayHelper.displayLabel(
            for: player,
            showFullNameAndNumber: viewModel.showFullNameAndNumberInBasketball
        )
    }

    func basketballLineupSectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .textCase(nil)
            .shadow(color: .black.opacity(0.45), radius: 2, x: 0, y: 1)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.black.opacity(0.22), in: Capsule())
    }

    func basketballLineupGroupedSection<Content: View>(
        _ title: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                basketballLineupSectionHeader(title)
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

    var basketballLineupRowDivider: some View {
        Divider()
            .padding(.leading, 46)
    }

    func ratingText(for player: Player, position: BasketballPosition) -> String {
        guard let rating = player.basketballPositionRatings[position] else {
            return "No rating"
        }

        return "Rating \(rating)"
    }

    func removeBasketballStarter(_ player: Player, from position: BasketballPosition) {
        guard !viewModel.basketballBenchPlayersRated(for: position).isEmpty else {
            basketballLineupWarningMessage = "No bench player has a rating for position \(position.rawValue)."
            return
        }

        pendingBasketballStarterPlayer = player
        pendingBasketballStarterPosition = position
        isShowingBasketballStarterReplacementChoices = true
    }

    func addBasketballBenchPlayer(_ player: Player) {
        let ratedPositions = BasketballPosition.allCases.filter { player.basketballPositionRatings[$0] != nil }

        guard !ratedPositions.isEmpty else {
            basketballLineupWarningMessage = "\(basketballLineupDisplayLabel(for: player)) does not have any position ratings."
            return
        }

        if ratedPositions.count == 1, let position = ratedPositions.first {
            replaceBasketballStarter(with: player, at: position)
            return
        }

        pendingBasketballBenchPlayer = player
        isShowingBasketballReplacementChoices = true
    }

    func replaceBasketballStarter(with benchPlayer: Player, at position: BasketballPosition) {
        guard let result = viewModel.forceReplaceBasketballStarter(at: position, with: benchPlayer.id) else { return }

        if let replacedPlayer = result.replaced {
            basketballLineupStatusMessage = "\(basketballLineupDisplayLabel(for: benchPlayer)) replaced \(basketballLineupDisplayLabel(for: replacedPlayer)) at position \(position.rawValue)."
        } else {
            basketballLineupStatusMessage = "\(basketballLineupDisplayLabel(for: benchPlayer)) entered at position \(position.rawValue)."
        }
    }

    func forceReplaceBasketballStarter(with playerID: UUID, at position: BasketballPosition) -> Bool {
        guard let result = viewModel.forceReplaceBasketballStarter(at: position, with: playerID) else {
            return false
        }

        if result.incomingIsRated, let replacedPlayer = result.replaced {
            basketballLineupStatusMessage = "\(basketballLineupDisplayLabel(for: result.incoming)) replaced \(basketballLineupDisplayLabel(for: replacedPlayer)) at position \(position.rawValue)."
        } else if result.incomingIsRated {
            basketballLineupStatusMessage = "\(basketballLineupDisplayLabel(for: result.incoming)) entered at position \(position.rawValue)."
        } else {
            basketballLineupStatusMessage = "This player is not rated for this position"
        }

        return true
    }

    func basketballReplacementOptionLabel(for position: BasketballPosition, benchPlayer: Player) -> String {
        let rating = benchPlayer.basketballPositionRatings[position].map { "Rating \($0)" } ?? "Rated"
        let starterName = viewModel.basketballStartingPlayer(for: position)
            .map { basketballLineupDisplayLabel(for: $0) } ?? "Empty spot"
        return "\(position.rawValue) - \(starterName) (\(rating))"
    }

    func basketballStarterReplacementOptionLabel(for benchPlayer: Player, at position: BasketballPosition) -> String {
        let rating = benchPlayer.basketballPositionRatings[position].map { "Rating \($0)" } ?? "Rated"
        return "\(basketballLineupDisplayLabel(for: benchPlayer)) (\(rating))"
    }

    func prepareBasketballLineupShare() {
        do {
            let shareText = basketballLineupTextExport()
            let fileURL = viewModel.sharedFileURL(fileDescription: "Starting Lineup", fileExtension: "txt")

            try shareText.write(to: fileURL, atomically: true, encoding: .utf8)

            basketballLineupShareURL = fileURL
            basketballLineupExportMessage = "Starting lineup ready."
            isShowingBasketballLineupShareSheet = true
        } catch {
            basketballLineupWarningMessage = "Could not create the starting lineup file."
        }
    }

    func basketballLineupTextExport() -> String {
        var lines = ["\(viewModel.selectedTeamName) Starting Lineup", ""]

        for position in BasketballPosition.allCases {
            if let player = viewModel.basketballStartingPlayer(for: position) {
                lines.append(basketballLineupDisplayLabel(for: player))
            } else {
                lines.append("Empty")
            }
        }

        lines.append("")
        lines.append("Bench")

        let benchPlayers = viewModel.basketballBenchPlayers
        if benchPlayers.isEmpty {
            lines.append("None")
        } else {
            for player in benchPlayers {
                lines.append(basketballLineupDisplayLabel(for: player))
            }
        }

        return lines.joined(separator: "\n")
    }

    func handleBasketballLineupDrop(_ providers: [NSItemProvider], toStartingIndex index: Int) -> Bool {
        loadDraggedBasketballPlayerID(from: providers) { playerID in
            _ = handleBasketballLineupDrop(playerID, toStartingIndex: index)
        }
    }

    func handleBasketballLineupDrop(_ playerID: UUID, toStartingIndex index: Int) -> Bool {
        guard BasketballPosition.allCases.indices.contains(index) else { return false }

        return forceReplaceBasketballStarter(with: playerID, at: BasketballPosition.allCases[index])
    }

    func handleBasketballBenchDrop(_ providers: [NSItemProvider], on player: Player) -> Bool {
        loadDraggedBasketballPlayerID(from: providers) { playerID in
            _ = handleBasketballBenchDrop(playerID, on: player)
        }
    }

    func handleBasketballBenchDrop(_ playerID: UUID, on benchPlayer: Player) -> Bool {
        if let position = viewModel.basketballStartingPosition(for: playerID) {
            return forceReplaceBasketballStarter(with: benchPlayer.id, at: position)
        }

        viewModel.moveBasketballLineupPlayer(playerID: playerID, beforePlayerID: benchPlayer.id)
        return true
    }

    var basketballDropTypes: [UTType] {
        [.plainText, .text]
    }

    private func loadDraggedBasketballPlayerID(from providers: [NSItemProvider], action: @escaping (UUID) -> Void) -> Bool {
        guard let dropMatch = providers.lazy.compactMap({ provider -> (NSItemProvider, String)? in
            guard let type = basketballDropTypes.first(where: { provider.hasItemConformingToTypeIdentifier($0.identifier) }) else {
                return nil
            }

            return (provider, type.identifier)
        }).first else {
            return false
        }

        let (provider, typeIdentifier) = dropMatch
        provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, _ in
            let rawID: String?

            if let data = item as? Data {
                rawID = String(data: data, encoding: .utf8)
            } else if let string = item as? String {
                rawID = string
            } else if let nsString = item as? NSString {
                rawID = nsString as String
            } else {
                rawID = nil
            }

            guard let rawID, let playerID = UUID(uuidString: rawID) else { return }

            DispatchQueue.main.async {
                action(playerID)
            }
        }

        return true
    }
}

extension View {
    @ViewBuilder
    func basketballLineupDragSource(player: Player?) -> some View {
        if let player {
            self.draggable(player.id.uuidString)
        } else {
            self
        }
    }
}
