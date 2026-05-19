//
//  PitchHistoryCSVExporter.swift
//  Lineup Changer Catchercom
//
//  Created by Rich Morris on 5/18/26.
//

import Foundation

// MARK: - Export File

struct PitchHistoryExportFile: Identifiable {
    let id = UUID()
    let url: URL
}

// MARK: - CSV Exporter

enum PitchHistoryCSVExporter {
    // MARK: File Creation

    static func makeFile(from history: [CallHistoryItem]) -> PitchHistoryExportFile? {
        // Export to a dated temp file so the iOS share sheet can save, text, or email the CSV.
        let fileName = "Pitches_\(fileDateFormatter.string(from: Date())).csv"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        let csvText = makeCSV(from: history)

        do {
            try csvText.write(to: fileURL, atomically: true, encoding: .utf8)
            return PitchHistoryExportFile(url: fileURL)
        } catch {
            return nil
        }
    }

    // MARK: CSV Formatting

    private static func makeCSV(from history: [CallHistoryItem]) -> String {
        var rows = ["Date,Time,Pitch"]

        rows.append(contentsOf: history.map { item in
            [
                csvField(displayDateFormatter.string(from: item.sentAt)),
                csvField(displayTimeFormatter.string(from: item.sentAt)),
                csvField(item.title)
            ].joined(separator: ",")
        })

        return rows.joined(separator: "\n")
    }

    private static func csvField(_ value: String) -> String {
        // Quote every field so commas in a play name do not break the CSV columns.
        let escapedValue = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escapedValue)\""
    }

    // MARK: Formatters

    private static let fileDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    private static let displayTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter
    }()
}
