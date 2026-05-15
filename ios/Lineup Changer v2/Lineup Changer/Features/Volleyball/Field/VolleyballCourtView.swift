// Created by Rich Morris on 5/7/26.
// Lineup Changer
// VolleyballCourtView.swift
//
//
//
import SwiftUI

// MARK: - VolleyballCourt View
struct VolleyballCourtView: View {
    @ObservedObject var viewModel: LineupViewModel

    var body: some View {
        SportSurfacePreviewView(sport: .volleyball)
    }
}
