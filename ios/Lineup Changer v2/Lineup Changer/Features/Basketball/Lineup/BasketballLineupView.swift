// Created by Rich Morris on 5/13/26.
// Lineup Changer
// BasketballLineupView.swift
//
//
//
import SwiftUI

// MARK: - Basketball Lineup View
struct BasketballLineupView: View {
    @ObservedObject var viewModel: LineupViewModel

    @State var isShowingBasketballLineupShareSheet = false
    @State var basketballLineupShareURL: URL?
    @State var basketballLineupExportMessage = ""
    @State var basketballLineupStatusMessage = ""
    @State var basketballLineupWarningMessage = ""
    @State var pendingBasketballBenchPlayer: Player?
    @State var pendingBasketballStarterPlayer: Player?
    @State var pendingBasketballStarterPosition: BasketballPosition?
    @State var isShowingBasketballReplacementChoices = false
    @State var isShowingBasketballStarterReplacementChoices = false

    var body: some View {
        basketballLineupScreen
    }
}
