// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BasketballPlayerDetailView.swift
//
//
//
import SwiftUI
import MessageUI

// MARK: - Basketball Player Detail View
// Basketball player profile editor without baseball-only ratings.
enum BasketballPlayerDetailFocusedField: Hashable {
    case name
    case number
    case cell
    case notes
}

struct BasketballPlayerDetailView: View {
    @ObservedObject var viewModel: LineupViewModel
    let player: Player

    @State var editedName = ""
    @State var editedNumber = ""
    @State var editedCellNumber = ""
    @State var isGuestPlayer = false
    @State var selectedBasketballPosition: BasketballPosition = .one
    @State var selectedBasketballRating = 1
    @State var editedNotes = ""
    @State var isShowingMessageComposer = false
    @State var messageAlertText: String?
    @State var duplicateNumberAlertText: String?
    @FocusState var focusedField: BasketballPlayerDetailFocusedField?
    @Environment(\.dismiss) var dismiss

    var currentPlayer: Player? {
        viewModel.players.first(where: { $0.id == player.id })
    }

    var playerTitle: String {
        currentPlayer?.name ?? player.name
    }

    var availableBasketballPositions: [BasketballPosition] {
        BasketballPosition.allCases.filter { position in
            !(currentPlayer?.basketballPositionRatings.keys.contains(position) ?? false)
        }
    }

    var body: some View {
        basketballPlayerDetailScreen
    }
}
