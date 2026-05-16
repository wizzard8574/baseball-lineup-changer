// Created by Rich Morris on 5/15/26.
// Lineup Changer
// LineupViewModel+ShareFileNames.swift
//
//
//
import Foundation

// MARK: - Share File Names
extension LineupViewModel {
    func sharedFileURL(fileDescription: String, fileExtension: String) -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(
            "\(sharedFileName(fileDescription: fileDescription)).\(fileExtension)"
        )
    }

    func sharedFileName(fileDescription: String) -> String {
        [
            safeSharedFileComponent(selectedTeamName, fallback: "Team"),
            safeSharedFileComponent(selectedSport.rawValue, fallback: "Sport"),
            safeSharedFileComponent(fileDescription, fallback: "File")
        ]
        .joined(separator: "_")
    }

    private func safeSharedFileComponent(_ value: String, fallback: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        let safeValue = value
            .components(separatedBy: invalidCharacters)
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return safeValue.isEmpty ? fallback : safeValue
    }
}
