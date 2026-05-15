// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BaseballFieldView+FieldLayoutSections.swift
//
//
//
import SwiftUI

// MARK: - Field Layout Sections
extension BaseballFieldView {
    @ViewBuilder
    var fieldAndAssignedLineupSections: some View {
        if usesSideBySideFieldLayout {
            Section {
                HStack(alignment: .top, spacing: 18) {
                    VStack(alignment: .leading, spacing: 10) {
                        fieldSectionHeader("Field View")
                        fieldPreviewContent
                            .frame(minHeight: 440)
                    }
                    .frame(maxWidth: .infinity, alignment: .top)

                    if viewModel.showAssignedLineupTable {
                        VStack(alignment: .leading, spacing: 10) {
                            fieldSectionHeader("Assigned Lineup")
                            assignedLineupContent
                                .padding(.top, 40)
                        }
                        .frame(maxWidth: .infinity, alignment: .top)
                    }
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)
        } else {
            Section(header: fieldSectionHeader("Field View")) {
                fieldPreviewContent
                    .frame(height: UIScreen.main.bounds.width * 0.9)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            if viewModel.showAssignedLineupTable {
                Section(header: fieldSectionHeader("Assigned Lineup")) {
                    assignedLineupContent
                }
            }
        }
    }
}
