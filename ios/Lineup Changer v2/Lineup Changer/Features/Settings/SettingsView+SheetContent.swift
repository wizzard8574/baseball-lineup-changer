// Created by Rich Morris on 5/5/26.
// Lineup Changer
// SettingsView+SheetContent.swift
//
//
//
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Settings Sheet Content
extension SettingsView {
    @ViewBuilder
    func settingsSheetContent(_ sheet: SettingsPresentedSheet) -> some View {
        switch sheet {
        // Player import sheet handles both lightweight and full player-data imports.
        case .playerImport:
            ImportDocumentPicker(
                contentTypes: [.json, .data],
                onPick: { url in
                    handlePlayerImport(url)
                },
                onCancel: {
                    backupStatusMessage = "Import cancelled."
                    presentedSheet = nil
                }
            )
        // Coach import sheet.
        case .coachImport:
            ImportDocumentPicker(
                contentTypes: [.json, .data],
                onPick: { url in
                    handleCoachImport(url)
                },
                onCancel: {
                    backupStatusMessage = "Coach import cancelled."
                    presentedSheet = nil
                }
            )
        // GameChanger CSV import sheet.
        case .gameChangerImport:
            ImportDocumentPicker(
                contentTypes: [.commaSeparatedText, .plainText, .data],
                onPick: { url in
                    handleGameChangerImport(url)
                },
                onCancel: {
                    gameChangerStatusMessage = "Import cancelled."
                    presentedSheet = nil
                }
            )
        // Native iOS share sheet for generated export files.
        case .share(let url):
            ActivityView(activityItems: [url])
        }
    }
}
