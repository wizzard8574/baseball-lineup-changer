//
//  LineupViewModel+Persistence.swift
//  Lineup Changer
//
//  Created by Rich Morris on 5/3/26.
//

import Foundation
import SwiftUI
import UIKit
import Combine

extension LineupViewModel {
    
    func save() {
        guard !isApplyingSavedState else { return }

        do {
            let data = try JSONEncoder().encode(currentAppState())
            UserDefaults.standard.set(data, forKey: saveKey)
        } catch {
            print("Failed to save app state: \(error)")
        }
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else { return }

        do {
            isApplyingSavedState = true
            defer { isApplyingSavedState = false }

            let state = try JSONDecoder().decode(AppState.self, from: data)
            applyAppState(state)
        } catch {
            isApplyingSavedState = false
            print("Failed to load app state: \(error)")
            UserDefaults.standard.set(data, forKey: "LineupChangerRecoveryBackup")
        }
    }
 
    func currentAppState() -> AppState {
        teamSnapshots[selectedTeamIndex] = currentTeamSnapshot()
        let savedSnapshots = teamSnapshots.enumerated().map { index, snapshot in
            snapshot ?? emptyTeamSnapshot()
        }

        return AppState(
            players: players,
            coaches: coaches,
            pitcherID: pitcherID,
            catcherID: catcherID,
            lineup: lineup,
            selectedInning: selectedInning,
            inningLineups: inningLineups,
            inningPitcherIDs: inningPitcherIDs,
            inningCatcherIDs: inningCatcherIDs,
            showRatingsOnField: showRatingsOnField,
            showAssignedLineupTable: showAssignedLineupTable,
            showFullNameAndNumber: showFullNameAndNumber,
            showBenchOnField: showBenchOnField,
            showOnlyNineBattersAndDH: showOnlyNineBattersAndDH,
            showSlowSpeedBattingWarnings: showSlowSpeedBattingWarnings,
            fallBallEnabled: fallBallEnabled,
            fallBallYouthEnabled: fallBallYouthEnabled,
            battingOrderIDs: battingOrderIDs,
            designatedHitterID: designatedHitterID,
            designatedHitterForID: designatedHitterForID,
            preGameNotes: preGameNotes,
            postGameNotes: postGameNotes,
            coachNotes: coachNotes,
            selectedSport: selectedSport,
            selectedTeamIndex: selectedTeamIndex,
            teamNames: teamNames,
            teamSnapshots: savedSnapshots
        )
    }

    func applyAppState(_ state: AppState) {
        if let savedNames = state.teamNames, savedNames.count >= 2 {
            teamNames = Array(savedNames.prefix(2))
        }

        selectedTeamIndex = min(max(state.selectedTeamIndex ?? 0, 0), 1)

        let savedSnapshots = state.teamSnapshots
        if savedSnapshots.count >= 2 {
            teamSnapshots = [savedSnapshots[0], savedSnapshots[1]]
            applyTeamSnapshot(savedSnapshots[selectedTeamIndex])
        } else {
            let legacySnapshot = TeamSnapshot(
                players: state.players,
                coaches: state.coaches,
                pitcherID: state.pitcherID,
                catcherID: state.catcherID,
                lineup: state.lineup,
                selectedInning: state.selectedInning,
                inningLineups: state.inningLineups,
                inningPitcherIDs: state.inningPitcherIDs,
                inningCatcherIDs: state.inningCatcherIDs,
                battingOrderIDs: state.battingOrderIDs,
                designatedHitterID: state.designatedHitterID,
                designatedHitterForID: state.designatedHitterForID,
                preGameNotes: state.preGameNotes,
                postGameNotes: state.postGameNotes,
                coachNotes: state.coachNotes,
                selectedSport: state.selectedSport
            )
            teamSnapshots = [legacySnapshot, emptyTeamSnapshot()]
            applyTeamSnapshot(legacySnapshot)
        }

        showRatingsOnField = state.showRatingsOnField
        showAssignedLineupTable = state.showAssignedLineupTable
        showFullNameAndNumber = state.showFullNameAndNumber
        showBenchOnField = state.showBenchOnField
        showOnlyNineBattersAndDH = state.showOnlyNineBattersAndDH
        showSlowSpeedBattingWarnings = state.showSlowSpeedBattingWarnings
        fallBallEnabled = state.fallBallEnabled ?? false
        fallBallYouthEnabled = fallBallEnabled ? (state.fallBallYouthEnabled ?? false) : false
        selectedSport = state.selectedSport ?? .baseballSoftball
    }
   
    func emptyTeamSnapshot() -> TeamSnapshot {
        TeamSnapshot(
            players: [],
            coaches: [],
            pitcherID: nil,
            catcherID: nil,
            lineup: [:],
            selectedInning: 1,
            inningLineups: [:],
            inningPitcherIDs: [:],
            inningCatcherIDs: [:],
            battingOrderIDs: [],
            designatedHitterID: nil,
            designatedHitterForID: nil,
            preGameNotes: "",
            postGameNotes: "",
            coachNotes: "",
            selectedSport: .baseballSoftball
        )
    }

    func currentTeamSnapshot() -> TeamSnapshot {
        saveCurrentInningState()
        return TeamSnapshot(
            players: players,
            coaches: coaches,
            pitcherID: pitcherID,
            catcherID: catcherID,
            lineup: lineup,
            selectedInning: selectedInning,
            inningLineups: inningLineups,
            inningPitcherIDs: inningPitcherIDs,
            inningCatcherIDs: inningCatcherIDs,
            battingOrderIDs: battingOrderIDs,
            designatedHitterID: designatedHitterID,
            designatedHitterForID: designatedHitterForID,
            preGameNotes: preGameNotes,
            postGameNotes: postGameNotes,
            coachNotes: coachNotes,
            selectedSport: selectedSport
        )
    }

    func applyTeamSnapshot(_ snapshot: TeamSnapshot) {
        players = snapshot.players
        coaches = snapshot.coaches ?? []
        pitcherID = snapshot.pitcherID
        catcherID = snapshot.catcherID
        lineup = snapshot.lineup
        selectedInning = min(max(snapshot.selectedInning, 1), numberOfInnings)
        inningLineups = snapshot.inningLineups
        inningPitcherIDs = snapshot.inningPitcherIDs
        inningCatcherIDs = snapshot.inningCatcherIDs
        battingOrderIDs = snapshot.battingOrderIDs
        designatedHitterID = snapshot.designatedHitterID
        designatedHitterForID = snapshot.designatedHitterForID
        preGameNotes = snapshot.preGameNotes ?? ""
        postGameNotes = snapshot.postGameNotes ?? ""
        coachNotes = snapshot.coachNotes ?? ""
        selectedSport = snapshot.selectedSport ?? .baseballSoftball

        if inningLineups[selectedInning] == nil {
            inningLineups[selectedInning] = lineup
        } else {
            lineup = inningLineups[selectedInning] ?? [:]
        }

        pitcherID = inningPitcherIDs[selectedInning] ?? snapshot.pitcherID
        catcherID = inningCatcherIDs[selectedInning] ?? snapshot.catcherID
        syncBattingOrder()
    }

    
    
}
