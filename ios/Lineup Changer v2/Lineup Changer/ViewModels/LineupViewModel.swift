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
    @Published var lineup: [FieldPosition: UUID] = [:]

    // MARK: - Inning State
    // Inning currently being viewed or edited.
    @Published var selectedInning = 1
    // Saved defensive lineups for each inning.
    @Published var inningLineups: [Int: [FieldPosition: UUID]] = [:]
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
    // Shows or hides basketball player ratings on the court view.
    @Published var showRatingsOnCourt = true { didSet { save() } }
    // Shows or hides the basketball assigned lineup section on the court view.
    @Published var showAssignedBasketballLineup = true { didSet { save() } }
    // Shows or hides the basketball bench section on the court view.
    @Published var showBasketballBenchOnCourt = true { didSet { save() } }
    // true = full name and number. false = first name and number for basketball lineup/court.
    @Published var showFullNameAndNumberInBasketball = true { didSet { save() } }
    // Controls whether basketball games use four quarters or two halves.
    @Published var basketballPeriodFormat: BasketballPeriodFormat = .quarters { didSet { save() } }
    // Enables youth basketball settings.
    @Published var basketballYouthEnabled = false {
        didSet {
            if !basketballYouthEnabled {
                basketballQuartersPlayedEnabled = false
            }
            save()
        }
    }
    // Youth basketball option that tries to guarantee a minimum number of quarters for each player.
    @Published var basketballQuartersPlayedEnabled = false { didSet { save() } }
    // Required quarters per player when Youth Quarters Played is enabled.
    @Published var basketballRequiredQuartersPlayed = 2 {
        didSet {
            let clamped = min(max(basketballRequiredQuartersPlayed, 1), BasketballPeriodFormat.quarters.periodCount)
            if clamped != basketballRequiredQuartersPlayed {
                basketballRequiredQuartersPlayed = clamped
            }
            save()
        }
    }
    // Stored with the legacy key, but now represents Roster Bat:
    // true shows the full roster, false uses the 9 batter + DH lineup.
    @Published var showOnlyNineBattersAndDH = false {
        didSet {
            if baseballUsesNineBatterAndDH && oldValue && !isApplyingSavedState {
                clearAllInnings()
                baseballLineupBatterCount = nil
                fallBallEnabled = false
                fallBallRunRuleEnabled = false
                fallBallYouthEnabled = false
            }

            syncDesignatedHitterSelection()
            save()
        }
    }
    // Enables batting-order warnings for slow runners around pitcher/catcher placement.
    @Published var showSlowSpeedBattingWarnings = true { didSet { save() } }

    // MARK: - Game Format Settings
    // Number of innings used for lineup generation and inning selection.
    @Published var numberOfInnings: Int = 7 {
        didSet {
            // Keep inning count inside the supported 1...12 range.
            let clamped = min(max(numberOfInnings, 1), 12)
            if clamped != numberOfInnings { numberOfInnings = clamped }
            // Store this setting separately so it is available before full app state loads.
            userDefaults.set(numberOfInnings, forKey: Self.numberOfInningsDefaultsKey)
        }
    }
    // Enables Fall Ball lineup generation rules.
    @Published var fallBallEnabled = false {
        didSet {
            if fallBallEnabled && baseballUsesNineBatterAndDH {
                fallBallEnabled = false
                return
            }

            if fallBallEnabled {
                fallBallRunRuleEnabled = false
            }
            // Youth mode only applies when Fall Ball is also enabled.
            if !fallBallEnabled {
                fallBallYouthEnabled = false
            }
            save()
        }
    }
    // Enables youth Fall Ball mode, where all positions can be randomized.
    @Published var fallBallYouthEnabled = false { didSet { save() } }
    // Enables Run Rule mode, where only pitcher is manual and auto-fill avoids 1-rated positions.
    @Published var fallBallRunRuleEnabled = false {
        didSet {
            if fallBallRunRuleEnabled && baseballUsesNineBatterAndDH {
                fallBallRunRuleEnabled = false
                return
            }

            if fallBallRunRuleEnabled {
                fallBallEnabled = false
                fallBallYouthEnabled = false
            }
            save()
        }
    }

    // MARK: - Batting Order State
    // Ordered player IDs used by the lineup tab.
    @Published var battingOrderIDs: [UUID] = [] { didSet { save() } }
    // Number of active baseball/softball batters currently shown in the batting order
    // when Roster Bat is off. nil keeps old saves at the default 9.
    @Published var baseballLineupBatterCount: Int? = nil { didSet { save() } }
    // Temporary warning shown when a user tries to exceed the 9 batter lineup limit.
    @Published var baseballLineupLimitWarningText: String?
    // Player selected as the designated hitter.
    @Published var designatedHitterID: UUID? { didSet { save() } }
    // Player the designated hitter is batting for.
    @Published var designatedHitterForID: UUID? { didSet { save() } }
    // Basketball starting lineup slots. When false, basketball falls back to the first five ordered players.
    @Published var basketballUsesExplicitStartingLineup = false { didSet { save() } }
    @Published var basketballStartingLineupIDs: [BasketballPosition: UUID] = [:] { didSet { save() } }
    // Basketball court assignments by quarter/half.
    @Published var basketballCourtLineupIDsByPeriod: [Int: [BasketballPosition: UUID]] = [:] { didSet { save() } }

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
    @Published var selectedSport: SportType = .baseballSoftball {
        didSet {
            guard selectedSport != oldValue, !isSelectingSport else { return }
            switchSport(from: oldValue, to: selectedSport)
        }
    }
    // GameChanger stats now live on Player records instead of separate view-model properties.

    // MARK: - Persistence Support State
    // Cached team snapshots used when switching between team slots.
    var teamSnapshots: [TeamSnapshot?] = [nil, nil]
    // Cached two-team state for each sport.
    var sportTeamStates: [SportType: SportTeamState] = [:]
    // Prevents save loops while restoring persisted state.
    var isApplyingSavedState = false
    // Prevents nested saves while a state snapshot is being encoded.
    var isSaving = false
    // Prevents the selectedSport didSet observer from duplicating explicit sport selections.
    var isSelectingSport = false
    // Storage used for app state and small launch-time settings.
    let userDefaults: UserDefaults
    // Random index source used by lineup generation. Tests can inject deterministic output.
    let lineupRandomIndex: (Int) -> Int
    // UserDefaults key for the encoded app state.
    let saveKey = "YouthPositionRanker.appState.v3"

    // MARK: - Initialization
    // Loads persisted state when the shared view model is created.
    init(userDefaults: UserDefaults = .standard,
         lineupRandomIndex: @escaping (Int) -> Int = { upperBound in Int.random(in: 0..<upperBound) }) {
        self.userDefaults = userDefaults
        self.lineupRandomIndex = lineupRandomIndex
        numberOfInnings = Self.loadSavedNumberOfInnings(from: userDefaults)
        load()
    }
}
