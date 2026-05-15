// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BaseballFieldView.swift
//
//
//
import SwiftUI

// MARK: - Baseball Field View
struct BaseballFieldView: View {
    @ObservedObject var viewModel: LineupViewModel

    @State var selectedFieldViewPosition: FieldPosition?
    @State var isShowingFieldPositionPlayerPicker = false
    @State var benchPlacementWarningText: String?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var usesSideBySideFieldLayout: Bool {
        UIDevice.current.userInterfaceIdiom == .pad && horizontalSizeClass == .regular
    }

    var body: some View {
        fieldScreen
    }
}
