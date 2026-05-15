// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BaseballPlayerDetailView.swift
//
//
//
import SwiftUI
import MessageUI


// MARK: - Player Detail Supporting Types

// Tracks which field is focused in the player detail form.
// Used by the keyboard toolbar to save and dismiss editing.

enum PlayerDetailFocusedField: Hashable {
    case name
    case number
    case cell
    case notes
}
// MARK: - Player Detail View
// Detail screen for viewing and editing a player profile.
// Edits are staged in local @State properties and saved back to the view model.
struct BaseballPlayerDetailView: View {
    // Shared app state that owns player updates, ratings, and persistence.
    @ObservedObject var viewModel: LineupViewModel
    // Player selected when this detail view was opened.
    let player: Player
    
    // Local editable copies of player profile fields.
    @State var editedName: String = ""
    @State var editedNumber: String = ""
    @State var editedCellNumber: String = ""
    // Local player status and rating selections.
    @State var isGuestPlayer = false
    @State var selectedSpeedRating: Int = 1
    @State var selectedPosition: FieldPosition = .firstBase
    @State var selectedRating: Int = 1
    // Local notes and messaging state.
    @State var editedNotes: String = ""
    @State var isShowingMessageComposer = false
    @State var messageAlertText: String?
    @State var duplicateNumberAlertText: String?
    // Tracks keyboard focus for editable fields.
    @FocusState var focusedField: PlayerDetailFocusedField?
    // Allows the Save button to close the detail screen.
    @Environment(\.dismiss) var dismiss
    
    // Looks up the latest version of this player from the view model.
    var currentPlayer: Player? {
        viewModel.players.first(where: { $0.id == player.id })
    }
    
    // Displayed in the branded toolbar title instead of the default large navigation title.
    var playerTitle: String {
        currentPlayer?.name ?? player.name
    }
    
    // Positions that do not already have a rating for this player.
    var availablePositions: [FieldPosition] {
        FieldPosition.allCases.filter { position in
            !(currentPlayer?.positionRatings.keys.contains(position) ?? false)
        }
    }
    // MARK: - Body
    // Main player editing form.
    var body: some View {
        playerDetailScreen
    }
}
