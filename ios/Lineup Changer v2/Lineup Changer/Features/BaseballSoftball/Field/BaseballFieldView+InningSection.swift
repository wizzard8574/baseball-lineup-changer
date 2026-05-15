// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BaseballFieldView+InningSection.swift
//
//
//
import SwiftUI

// MARK: - Inning Section
extension BaseballFieldView {
    var inningPickerSection: some View {
        Section(header: fieldSectionHeader("Inning - \(viewModel.selectedInning)")) {
            Picker("Inning", selection: Binding(
                get: { viewModel.selectedInning },
                set: { viewModel.selectInning($0) }
            )) {
                ForEach(1...viewModel.numberOfInnings, id: \.self) { inning in
                    Text("\(inning)").tag(inning)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: viewModel.numberOfInnings) { _, newValue in
                if viewModel.selectedInning > newValue {
                    viewModel.selectInning(newValue)
                }
            }
        }
    }
}
