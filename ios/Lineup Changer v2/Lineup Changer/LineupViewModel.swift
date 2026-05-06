// Created by Rich Morris on 5/5/26.
// Lineup Changer
// LineupViewModel.swift
//
//
//
// LineupViewModel.swift contains the central observable state object for the app.
// It stores roster, coach, team, inning, lineup, settings, notes, and selected sport state,
// while delegating larger feature areas to focused LineupViewModel extensions.
import Foundation
import SwiftUI
import UIKit
import Combine

// MARK: - Main View Model

// Runs view-model mutations on the main actor because this object drives SwiftUI state.
// Primary app state container shared across the main SwiftUI views.
@MainActor
final class LineupViewModel: ObservableObject {
    // MARK: - Roster and Coach State
    // Players currently stored for the selected team.
    @Published var players: [Player] = []
    // Coaches for the selected team. Changes are persisted immediately.
    @Published var coaches: [Coach] = [] { didSet { save() } }

    // MARK: - Current Field Assignments
    // Manually selected pitcher for the current inning.
    @Published var pitcherID: UUID?
    // Manually selected catcher for the current inning.
    @Published var catcherID: UUID?
    // Defensive field assignments for the currently selected inning.
    @Published var lineup: [FieldPosition: Player] = [:]

    // MARK: - Inning State
    // Inning currently being viewed or edited.
    @Published var selectedInning = 1
    // Saved defensive lineups for each inning.
    @Published var inningLineups: [Int: [FieldPosition: Player]] = [:]
    // Saved pitcher assignments by inning.
    @Published var inningPitcherIDs: [Int: UUID] = [:]
    // Saved catcher assignments by inning.
    @Published var inningCatcherIDs: [Int: UUID] = [:]

    // MARK: - Display Settings
    // Shows or hides player position ratings on the field markers.
    @Published var showRatingsOnField = true { didSet { save() } }
    // Shows or hides the editable assigned-lineup table below the field preview.
    @Published var showAssignedLineupTable = true { didSet { save() } }
    // true = full name and number. false = first initial, last name, and number.
    // Used by field, lineup, player, and picker displays.
    @Published var showFullNameAndNumber = true { didSet { save() } }
    // Shows or hides the bench section on the field screen.
    @Published var showBenchOnField = true { didSet { save() } }
    // Limits lineup display to nine batters and enables DH controls.
    @Published var showOnlyNineBattersAndDH = false { didSet { save() } }
    // Enables batting-order warnings for slow runners around pitcher/catcher placement.
    @Published var showSlowSpeedBattingWarnings = true { didSet { save() } }

    // MARK: - Game Format Settings
    // Number of innings used for lineup generation and inning selection.
    @Published var numberOfInnings: Int = LineupViewModel.loadSavedNumberOfInnings() {
        didSet {
            // Keep inning count inside the supported 1...12 range.
            let clamped = min(max(numberOfInnings, 1), 12)
            if clamped != numberOfInnings { numberOfInnings = clamped }
            // Store this setting separately so it is available before full app state loads.
            UserDefaults.standard.set(numberOfInnings, forKey: Self.numberOfInningsDefaultsKey)
        }
    }
    // Enables Fall Ball lineup generation rules.
    @Published var fallBallEnabled = false {
        didSet {
            // Youth mode only applies when Fall Ball is also enabled.
            if !fallBallEnabled {
                fallBallYouthEnabled = false
            }
            save()
        }
    }
    // Enables youth Fall Ball mode, where all positions can be randomized.
    @Published var fallBallYouthEnabled = false { didSet { save() } }

    // MARK: - Batting Order State
    // Ordered player IDs used by the lineup tab.
    @Published var battingOrderIDs: [UUID] = [] { didSet { save() } }
    // Player selected as the designated hitter.
    @Published var designatedHitterID: UUID? { didSet { save() } }
    // Player the designated hitter is batting for.
    @Published var designatedHitterForID: UUID? { didSet { save() } }

    // MARK: - Team State
    // Index of the currently selected team slot.
    @Published var selectedTeamIndex = 0
    // Display names for the available team slots.
    @Published var teamNames = ["Team 1", "Team 2"] { didSet { save() } }

    // MARK: - Notes State
    // Notes captured before the game.
    @Published var preGameNotes: String = "" { didSet { save() } }
    // Notes captured after the game.
    @Published var postGameNotes: String = "" { didSet { save() } }
    // General coach notes.
    @Published var coachNotes: String = "" { didSet { save() } }

    // MARK: - Sport Selection
    // Currently selected sport mode.
    @Published var selectedSport: SportType = .baseballSoftball { didSet { save() } }
    // GameChanger stats now live on Player records instead of separate view-model properties.

    // MARK: - Persistence Support State
    // Cached team snapshots used when switching between team slots.
    var teamSnapshots: [TeamSnapshot?] = [nil, nil]
    // Prevents save loops while restoring persisted state.
    var isApplyingSavedState = false
    // UserDefaults key for the encoded app state.
    let saveKey = "YouthPositionRanker.appState.v3"

    // MARK: - Initialization
    // Loads persisted state when the shared view model is created.
    init() {
        load()
    }

    // MARK: - Team Selection
    // Current team name, falling back to a generated name if the index is invalid.
    var selectedTeamName: String {
        guard teamNames.indices.contains(selectedTeamIndex) else { return "Team \(selectedTeamIndex + 1)" }
        return teamNames[selectedTeamIndex]
    }

    // Saves the current team snapshot, switches team slots, and restores that team's data.
    func selectTeam(_ index: Int) {
        // Only two team slots are supported, so clamp the requested index.
        let safeIndex = min(max(index, 0), 1)
        guard safeIndex != selectedTeamIndex else { return }

        // Preserve the outgoing team's state before switching.
        teamSnapshots[selectedTeamIndex] = currentTeamSnapshot()
        selectedTeamIndex = safeIndex

        // Restore an existing snapshot or start the destination team empty.
        if let snapshot = teamSnapshots[safeIndex] {
            applyTeamSnapshot(snapshot)
        } else {
            applyTeamSnapshot(emptyTeamSnapshot())
        }

        save()
    }

    // Renames the currently selected team after trimming blank space.
    func updateSelectedTeamName(_ newName: String) {
        // Ignore blank names so the team picker always has visible text.
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, teamNames.indices.contains(selectedTeamIndex) else { return }
        teamNames[selectedTeamIndex] = trimmed
        save()
    }

    // MARK: - Player Filters
    // Players eligible for lineup use. Guests are included with active players.
    var activePlayers: [Player] {
        players.filter { $0.status == .active || $0.status == .guest }
    }

    // MARK: - Display Helpers
    // Builds a player label based on the current full-name display setting.
    func displayLabel(for player: Player) -> String {
        // Split the name so compact display can use first initial and last name.
        let nameParts = player.name.split(separator: " ").map(String.init)
        let lastName = nameParts.last ?? player.name
        let firstInitial = nameParts.first?.first.map { "\($0)." } ?? ""
        let initialLastName = firstInitial.isEmpty ? lastName : "\(firstInitial) \(lastName)"

        // Full display keeps the complete name and optional jersey number.
        if showFullNameAndNumber {
            return player.number.isEmpty ? player.name : "#\(player.number) \(player.name)"
        }

        return player.number.isEmpty ? initialLastName : "#\(player.number) \(initialLastName)"
    }

    // MARK: - Defaults Helpers
    // UserDefaults key for the inning count setting.
    private static let numberOfInningsDefaultsKey = "numberOfInnings"

    // Loads the saved inning count, defaulting to seven if no valid value exists.
    private static func loadSavedNumberOfInnings() -> Int {
        // UserDefaults returns 0 when the key has never been set.
        let saved = UserDefaults.standard.integer(forKey: numberOfInningsDefaultsKey)
        return (1...12).contains(saved) ? saved : 7
    }


}
