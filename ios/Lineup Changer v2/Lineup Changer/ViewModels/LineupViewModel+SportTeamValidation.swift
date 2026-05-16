// Created by Rich Morris on 5/5/26.
// Lineup Changer
// LineupViewModel+SportTeamValidation.swift
//
//
//
import Foundation

// MARK: - Sport Team State
extension LineupViewModel {
    func resetCopiedTopLevelNames(from state: AppState) {
        guard let topLevelNames = state.teamNames else { return }

        let copiedNames = normalizedTeamNames(topLevelNames, for: .baseballSoftball)
        for sport in SportType.allCases where sport != .baseballSoftball {
            guard let sportState = sportTeamStates[sport] else { continue }
            if !sportTeamStateHasSavedContent(sportState),
               shouldResetCopiedTeamState(sportState, for: sport, copiedNames: copiedNames) {
                sportTeamStates[sport] = emptySportTeamState(for: sport)
            }
        }
    }

    func resetUncustomizedPlaceholderSportNames() {
        for sport in SportType.allCases where sport != .baseballSoftball {
            guard let sportState = sportTeamStates[sport], !sportState.hasCustomTeamNames else { continue }
            if !sportTeamStateHasSavedContent(sportState) {
                sportTeamStates[sport] = emptySportTeamState(for: sport)
            }
        }
    }

    func sportTeamStateHasSavedContent(_ state: SportTeamState) -> Bool {
        state.teamSnapshots.contains { snapshot in
            !snapshot.players.isEmpty
            || !(snapshot.coaches ?? []).isEmpty
            || !snapshot.battingOrderIDs.isEmpty
            || !snapshot.lineupIDs.isEmpty
            || snapshot.inningLineupIDs.values.contains { !$0.isEmpty }
            || snapshot.pitcherID != nil
            || snapshot.catcherID != nil
            || snapshot.showOnlyNineBattersAndDH == true
            || snapshot.showSlowSpeedBattingWarnings == false
            || snapshot.fallBallEnabled == true
            || snapshot.fallBallYouthEnabled == true
            || snapshot.fallBallRunRuleEnabled == true
            || snapshot.basketballYouthEnabled == true
            || snapshot.basketballQuartersPlayedEnabled == true
            || (snapshot.basketballRequiredQuartersPlayed != nil && snapshot.basketballRequiredQuartersPlayed != 2)
            || !(snapshot.preGameNotes ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !(snapshot.postGameNotes ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !(snapshot.coachNotes ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    func shouldResetCopiedTeamState(_ state: SportTeamState, for sport: SportType, copiedNames: [String]) -> Bool {
        let normalizedNames = normalizedTeamNames(state.teamNames, for: sport)
        let copiedFirstName = copiedNames.first?.trimmingCharacters(in: .whitespacesAndNewlines)
        let copiedSecondName = copiedNames.indices.contains(1) ? copiedNames[1].trimmingCharacters(in: .whitespacesAndNewlines) : ""

        if normalizedNames == copiedNames {
            return true
        }

        if !defaultTeamNames(for: .baseballSoftball).contains(copiedFirstName ?? ""),
           normalizedNames.first == copiedFirstName {
            return true
        }

        if !defaultTeamNames(for: .baseballSoftball).contains(copiedSecondName),
           normalizedNames.indices.contains(1),
           normalizedNames[1] == copiedSecondName {
            return true
        }

        return false
    }
}
