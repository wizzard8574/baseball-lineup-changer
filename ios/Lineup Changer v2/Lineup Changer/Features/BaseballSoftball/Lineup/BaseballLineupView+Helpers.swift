// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BaseballLineupView+Helpers.swift
//
//
//
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Lineup View Helpers
extension BaseballLineupView {
    var hasImportedGameChangerStats: Bool {
        viewModel.players.contains { $0.gameChangerStats != nil }
    }

    func lineupDisplayLabel(for player: Player) -> String {
        PlayerDisplayHelper.displayLabel(
            for: player,
            showFullNameAndNumber: viewModel.showFullNameAndNumber
        )
    }

    func lineupSectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .textCase(nil)
            .shadow(color: .black.opacity(0.45), radius: 2, x: 0, y: 1)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.black.opacity(0.22), in: Capsule())
    }

    func lineupGroupedSection<Content: View>(
        _ title: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                lineupSectionHeader(title)
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

    var lineupRowDivider: some View {
        Divider()
            .padding(.leading, 46)
    }

    func handleBaseballLineupDrop(_ providers: [NSItemProvider], toBattingOrderIndex index: Int) -> Bool {
        loadDraggedBaseballPlayerID(from: providers) { playerID in
            _ = handleBaseballLineupDrop(playerID, toBattingOrderIndex: index)
        }
    }

    func handleBaseballLineupDrop(_ playerID: UUID, toBattingOrderIndex index: Int) -> Bool {
        if viewModel.baseballUsesNineBatterAndDH {
            return viewModel.forceReplaceBaseballBatter(atBattingOrderIndex: index, with: playerID)
        }

        viewModel.moveBatter(playerID: playerID, toBattingOrderIndex: index)
        return true
    }

    func handleBaseballBenchDrop(_ providers: [NSItemProvider]) -> Bool {
        loadDraggedBaseballPlayerID(from: providers) { playerID in
            _ = handleBaseballBenchDrop(playerID)
        }
    }

    func handleBaseballBenchDrop(_ playerID: UUID) -> Bool {
        viewModel.moveBatterToBench(playerID: playerID)
        return true
    }

    func handleBaseballBenchDrop(_ providers: [NSItemProvider], before player: Player) -> Bool {
        loadDraggedBaseballPlayerID(from: providers) { playerID in
            _ = handleBaseballBenchDrop(playerID, on: player)
        }
    }

    func handleBaseballBenchDrop(_ playerID: UUID, on benchPlayer: Player) -> Bool {
        if viewModel.baseballUsesNineBatterAndDH,
           viewModel.baseballDisplayedBatters.contains(where: { $0.id == playerID }) {
            return viewModel.replaceBaseballLineupBatter(with: benchPlayer.id, for: playerID)
        }

        viewModel.moveBatter(playerID: playerID, beforeBenchPlayerID: benchPlayer.id)
        return true
    }

    var baseballDropTypes: [UTType] {
        [.plainText, .text]
    }

    private func loadDraggedBaseballPlayerID(from providers: [NSItemProvider], action: @escaping (UUID) -> Void) -> Bool {
        guard let dropMatch = providers.lazy.compactMap({ provider -> (NSItemProvider, String)? in
            guard let type = baseballDropTypes.first(where: { provider.hasItemConformingToTypeIdentifier($0.identifier) }) else {
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
    func baseballLineupDragSource(player: Player?) -> some View {
        if let player {
            self.draggable(player.id.uuidString)
        } else {
            self
        }
    }
}
