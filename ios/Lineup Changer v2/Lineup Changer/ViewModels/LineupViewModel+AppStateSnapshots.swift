// Created by Rich Morris on 5/5/26.
// Lineup Changer
// LineupViewModel+AppStateSnapshots.swift
//
//
//
// Builds and applies the persisted app-state model.
import Foundation

// MARK: - App State Snapshots
extension LineupViewModel {
    // Builds a complete AppState value from the current view-model state.
    func currentAppState() -> AppState {
        // Refresh the selected team's snapshot before collecting all team data.
        teamSnapshots[selectedTeamIndex] = currentTeamSnapshot(for: selectedSport)
        // Replace missing team snapshots with empty snapshots so the saved array is complete.
        let savedSnapshots = teamSnapshots.enumerated().map { index, snapshot in
            snapshot ?? emptyTeamSnapshot(for: selectedSport)
        }
        var savedSportTeamStates = sportTeamStates
        savedSportTeamStates[selectedSport] = SportTeamState(
            selectedTeamIndex: selectedTeamIndex,
            teamNames: normalizedTeamNames(teamNames, for: selectedSport),
            teamSnapshots: savedSnapshots,
            hasCustomTeamNames: sportTeamStates[selectedSport]?.hasCustomTeamNames ?? false
        )

        // Assemble global settings plus current/team-specific state into one persisted object.
        return AppState(
            players: players,
            coaches: coaches,
            pitcherID: pitcherID,
            catcherID: catcherID,
            lineup: resolvedLineup,
            lineupIDs: lineup,
            selectedInning: selectedInning,
            inningLineups: resolvedInningLineups(from: inningLineups),
            inningLineupIDs: inningLineups,
            inningPitcherIDs: inningPitcherIDs,
            inningCatcherIDs: inningCatcherIDs,
            showRatingsOnField: showRatingsOnField,
            showAssignedLineupTable: showAssignedLineupTable,
            showFullNameAndNumber: showFullNameAndNumber,
            showBenchOnField: showBenchOnField,
            showRatingsOnCourt: showRatingsOnCourt,
            showAssignedBasketballLineup: showAssignedBasketballLineup,
            showBasketballBenchOnCourt: showBasketballBenchOnCourt,
            showFullNameAndNumberInBasketball: showFullNameAndNumberInBasketball,
            basketballPeriodFormat: basketballPeriodFormat,
            showOnlyNineBattersAndDH: showOnlyNineBattersAndDH,
            showSlowSpeedBattingWarnings: showSlowSpeedBattingWarnings,
            fallBallEnabled: fallBallEnabled,
            fallBallYouthEnabled: fallBallYouthEnabled,
            fallBallRunRuleEnabled: fallBallRunRuleEnabled,
            battingOrderIDs: battingOrderIDs,
            baseballLineupBatterCount: baseballLineupBatterCount,
            designatedHitterID: designatedHitterID,
            designatedHitterForID: designatedHitterForID,
            basketballUsesExplicitStartingLineup: basketballUsesExplicitStartingLineup,
            basketballStartingLineupIDs: basketballStartingLineupIDs,
            basketballCourtLineupIDsByPeriod: basketballCourtLineupIDsByPeriod,
            preGameNotes: preGameNotes,
            postGameNotes: postGameNotes,
            coachNotes: coachNotes,
            selectedSport: selectedSport,
            selectedTeamIndex: selectedTeamIndex,
            teamNames: teamNames,
            teamSnapshots: savedSnapshots,
            sportTeamStates: savedSportTeamStates
        )
    }

    // Applies a decoded current-format AppState to the view model.
    func applyAppState(_ state: AppState) {
        let wasApplyingSavedState = isApplyingSavedState
        isApplyingSavedState = true
        defer { isApplyingSavedState = wasApplyingSavedState }

        let savedSelectedSport = state.selectedSport ?? .baseballSoftball
        sportTeamStates = state.sportTeamStates

        if sportTeamStates.isEmpty {
            sportTeamStates[.baseballSoftball] = topLevelTeamState(from: state, for: .baseballSoftball)
        }

        resetCopiedTopLevelNames(from: state)
        resetUncustomizedPlaceholderSportNames()

        selectedSport = savedSelectedSport
        if sportTeamStates[selectedSport] == nil {
            sportTeamStates[selectedSport] = emptySportTeamState(for: selectedSport)
        }
        applySportTeamState(
            sportTeamStates[selectedSport] ?? emptySportTeamState(for: selectedSport),
            for: selectedSport
        )

        // Restore global display and gameplay settings after team data is applied.
        showRatingsOnField = state.showRatingsOnField
        showAssignedLineupTable = state.showAssignedLineupTable
        showFullNameAndNumber = state.showFullNameAndNumber
        showBenchOnField = state.showBenchOnField
        showRatingsOnCourt = state.showRatingsOnCourt ?? true
        showAssignedBasketballLineup = state.showAssignedBasketballLineup ?? true
        showBasketballBenchOnCourt = state.showBasketballBenchOnCourt ?? true
        showFullNameAndNumberInBasketball = state.showFullNameAndNumberInBasketball ?? true
        basketballPeriodFormat = state.basketballPeriodFormat ?? .quarters
        showOnlyNineBattersAndDH = state.showOnlyNineBattersAndDH
        baseballLineupBatterCount = state.baseballLineupBatterCount
        basketballUsesExplicitStartingLineup = state.basketballUsesExplicitStartingLineup ?? false
        basketballStartingLineupIDs = state.basketballStartingLineupIDs ?? [:]
        basketballCourtLineupIDsByPeriod = state.basketballCourtLineupIDsByPeriod ?? [:]
        showSlowSpeedBattingWarnings = state.showSlowSpeedBattingWarnings
        fallBallEnabled = state.fallBallEnabled ?? false
        fallBallRunRuleEnabled = state.fallBallRunRuleEnabled ?? false
        fallBallYouthEnabled = fallBallEnabled ? (state.fallBallYouthEnabled ?? false) : false
    }
}

// MARK: - Lineup Resolution Helpers
extension LineupViewModel {
    // Resolves player-ID inning assignments into Player-valued lineups for export display fields.
    func resolvedInningLineups(from lineups: [Int: [FieldPosition: UUID]]) -> [Int: [FieldPosition: Player]] {
        Dictionary(uniqueKeysWithValues: lineups.map { inning, lineup in
            (inning, resolvedLineup(from: lineup))
        })
    }
}
