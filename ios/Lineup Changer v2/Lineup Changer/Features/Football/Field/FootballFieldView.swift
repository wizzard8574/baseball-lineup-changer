// Created by Rich Morris on 5/7/26.
// Lineup Changer
// FootballFieldView.swift
//
//
//
import SwiftUI

// MARK: - FootballField View
struct FootballFieldView: View {
    @ObservedObject var viewModel: LineupViewModel

    var body: some View {
        SportSurfacePreviewView(sport: .football)
    }
}
