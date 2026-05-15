// Created by Rich Morris on 5/7/26.
// Lineup Changer
// BasketballCourtView.swift
//
//
//
import SwiftUI

// MARK: - BasketballCourt View
struct BasketballCourtView: View {
    @ObservedObject var viewModel: LineupViewModel

    @State var selectedBasketballPeriod = 1
    @State var selectedCourtPosition: BasketballPosition?
    @State var isShowingCourtPositionPlayerPicker = false
    @State var basketballCourtBenchPlacementWarningText: String?

    var body: some View {
        basketballCourtScreen
    }
}
