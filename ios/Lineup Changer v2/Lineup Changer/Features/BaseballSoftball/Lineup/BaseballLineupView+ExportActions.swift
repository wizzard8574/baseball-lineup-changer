// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BaseballLineupView+ExportActions.swift
//
//
//
import SwiftUI

// MARK: - Export Actions
extension BaseballLineupView {
    var printSaveSection: some View {
        lineupGroupedSection("Print / Save") {
            Button {
                do {
                    lineupPDFURL = try viewModel.createLineupGridPDF()
                    isShowingLineupShareSheet = true
                    lineupExportMessage = "Lineup grid ready."
                } catch {
                    lineupExportMessage = "Could not create lineup grid: \(error.localizedDescription)"
                }
            } label: {
                Label("Share Lineup Grid", systemImage: "square.and.arrow.up")
            }
            .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)

            lineupRowDivider

            Button {
                do {
                    scorebookPDFURL = try viewModel.createScorebookPDF()
                    lineupPDFURL = scorebookPDFURL
                    isShowingLineupShareSheet = true
                    lineupExportMessage = "Scorebook ready."
                } catch {
                    lineupExportMessage = "Could not create scorebook: \(error.localizedDescription)"
                }
            } label: {
                Label("Share Book", systemImage: "book")
            }
            .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)

            if !lineupExportMessage.isEmpty {
                lineupRowDivider

                Text(lineupExportMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 10)
            }
        }
    }
}
