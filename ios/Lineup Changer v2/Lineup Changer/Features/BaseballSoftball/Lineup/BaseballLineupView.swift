// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BaseballLineupView.swift
//
//
//
import SwiftUI

// MARK: - Baseball Lineup View
struct BaseballLineupView: View {
    @ObservedObject var viewModel: LineupViewModel

    @State var isShowingLineupShareSheet = false
    @State var lineupPDFURL: URL?
    @State var scorebookPDFURL: URL?
    @State var lineupExportMessage = ""

    // MARK: - Body
    var body: some View {
        lineupScreen
    }
}
