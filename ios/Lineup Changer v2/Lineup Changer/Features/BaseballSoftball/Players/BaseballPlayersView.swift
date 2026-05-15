// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BaseballPlayersView.swift
//
//
//
// BaseballPlayersView contains the baseball/softball Players tab UI.
// It manages coach creation, player creation, roster navigation, and status actions.
import SwiftUI

// MARK: - Baseball / Softball Players View
// Full roster management layout for baseball/softball.
struct BaseballPlayersView: View {
    // Shared roster, coach, team, and sport state.
    @ObservedObject var viewModel: LineupViewModel
    // Draft text for the add-player and add-coach fields.
    @State var newPlayerName = ""
    @State var newCoachName = ""
    // Newly created records are assigned here to push directly into detail screens.
    @State var newPlayerDraft: Player?
    @State var newCoachDraft: Coach?
    // Tracks keyboard focus for the add-player and add-coach text fields.
    @FocusState var focusedField: PlayerListFocusedField?

    // MARK: - Focus Fields
    // Identifies which add field currently owns keyboard focus.
    enum PlayerListFocusedField {
        case newPlayer
        case newCoach
    }

    // MARK: - Body
    var body: some View {
        playersScreen
    }

}
