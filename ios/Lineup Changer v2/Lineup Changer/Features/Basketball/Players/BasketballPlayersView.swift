// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BasketballPlayersView.swift
//
//
//
import SwiftUI
import Foundation

// MARK: - Basketball Players View
// Basketball-specific roster screen.
// It keeps the shared team/player storage, but avoids baseball-only position ratings.
struct BasketballPlayersView: View {
    @ObservedObject var viewModel: LineupViewModel

    @State var newPlayerName = ""
    @State var newCoachName = ""
    @State var newPlayerDraft: Player?
    @State var newCoachDraft: Coach?
    @State var gameChangerSortStat: BasketballGameChangerPlayerSortStat?
    @FocusState var focusedField: BasketballPlayerListFocusedField?

    var body: some View {
        basketballPlayersScreen
    }
}

enum BasketballPlayerListFocusedField {
    case newPlayer
    case newCoach
}

enum BasketballGameChangerPlayerSortStat: String {
    case ppg = "PPG"
    case topg = "TOPG"
    case rpg = "RPG"
    case apg = "APG"
    case spg = "SPG"
    case bpg = "BPG"
    case trueShootingPercentage = "TS%"
    case assistTurnoverRatio = "AST/TO"
}
