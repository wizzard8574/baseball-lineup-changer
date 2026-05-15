// Created by Rich Morris on 5/7/26.
// Lineup Changer
// SoccerFieldView.swift
//
//
//
import SwiftUI

// MARK: - SoccerField View
struct SoccerFieldView: View {
    @ObservedObject var viewModel: LineupViewModel

    var body: some View {
        SportSurfacePreviewView(sport: .soccer)
    }
}
