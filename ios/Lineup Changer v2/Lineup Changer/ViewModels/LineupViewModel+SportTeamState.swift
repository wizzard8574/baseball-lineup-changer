// Created by Rich Morris on 5/5/26.
// Lineup Changer
// LineupViewModel+SportTeamState.swift
//
//
//
import Foundation

// MARK: - Sport Team State
extension LineupViewModel {
    func switchSport(from oldSport: SportType, to newSport: SportType) {
        guard !isApplyingSavedState else { return }

        let outgoingTeamNames = normalizedTeamNames(teamNames, for: oldSport)
        sportTeamStates[oldSport] = currentSportTeamState(for: oldSport)
        let incomingTeamState = sportTeamStateForSwitching(
            to: newSport,
            replacingNamesCopiedFrom: outgoingTeamNames
        )

        isApplyingSavedState = true
        applySportTeamState(
            incomingTeamState,
            for: newSport
        )
        isApplyingSavedState = false

        save()
    }

    func currentSportTeamState(for sport: SportType) -> SportTeamState {
        teamSnapshots[selectedTeamIndex] = currentTeamSnapshot(for: sport)
        let savedSnapshots = teamSnapshots.enumerated().map { _, snapshot in
            snapshot ?? emptyTeamSnapshot(for: sport)
        }
        return SportTeamState(
            selectedTeamIndex: selectedTeamIndex,
            teamNames: normalizedTeamNames(teamNames, for: sport),
            teamSnapshots: savedSnapshots,
            hasCustomTeamNames: sportTeamStates[sport]?.hasCustomTeamNames ?? false
        )
    }

    func emptySportTeamState(for sport: SportType) -> SportTeamState {
        SportTeamState(
            selectedTeamIndex: 0,
            teamNames: defaultTeamNames(for: sport),
            teamSnapshots: [
                emptyTeamSnapshot(for: sport),
                emptyTeamSnapshot(for: sport)
            ],
            hasCustomTeamNames: false
        )
    }

    func sportTeamStateForSwitching(to sport: SportType, replacingNamesCopiedFrom copiedNames: [String]) -> SportTeamState {
        guard let savedSportState = sportTeamStates[sport] else {
            let emptyState = emptySportTeamState(for: sport)
            sportTeamStates[sport] = emptyState
            return emptyState
        }

        if sport != .baseballSoftball,
           !sportTeamStateHasSavedContent(savedSportState),
           (!savedSportState.hasCustomTeamNames || shouldResetCopiedTeamState(savedSportState, for: sport, copiedNames: copiedNames)) {
            let emptyState = emptySportTeamState(for: sport)
            sportTeamStates[sport] = emptyState
            return emptyState
        }

        return savedSportState
    }

    func topLevelTeamState(from state: AppState, for sport: SportType) -> SportTeamState {
        SportTeamState(
            selectedTeamIndex: min(max(state.selectedTeamIndex ?? 0, 0), 1),
            teamNames: normalizedTeamNames(state.teamNames ?? defaultTeamNames(for: sport), for: sport),
            teamSnapshots: normalizedTeamSnapshots(state.teamSnapshots, for: sport),
            hasCustomTeamNames: normalizedTeamNames(state.teamNames ?? defaultTeamNames(for: sport), for: sport) != defaultTeamNames(for: sport)
        )
    }

    func applySportTeamState(_ state: SportTeamState, for sport: SportType) {
        teamNames = normalizedTeamNames(state.teamNames, for: sport)
        selectedTeamIndex = min(max(state.selectedTeamIndex, 0), 1)

        let savedSnapshots = normalizedTeamSnapshots(state.teamSnapshots, for: sport).map(Optional.some)
        teamSnapshots = savedSnapshots + Array(repeating: Optional.some(emptyTeamSnapshot(for: sport)), count: max(0, 2 - savedSnapshots.count))
        applyTeamSnapshot(teamSnapshots[selectedTeamIndex] ?? emptyTeamSnapshot(for: sport))
    }

}

