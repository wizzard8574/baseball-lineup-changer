// Created by Rich Morris on 5/5/26.
// Lineup Changer
// LineupViewModel+TeamSnapshots.swift
//
//
//
// Team snapshot creation and restoration helpers.
import Foundation

// MARK: - Team Snapshots
extension LineupViewModel {
    // Creates a blank team snapshot used for empty team slots.
    func emptyTeamSnapshot(for sport: SportType? = nil) -> TeamSnapshot {
        let sport = sport ?? selectedSport
        // All team-specific collections start empty and settings fall back to baseball/softball.
        return TeamSnapshot(
            players: [],
            coaches: [],
            pitcherID: nil,
            catcherID: nil,
            lineup: [:],
            lineupIDs: [:],
            selectedInning: 1,
            inningLineups: [:],
            inningLineupIDs: [:],
            inningPitcherIDs: [:],
            inningCatcherIDs: [:],
            battingOrderIDs: [],
            baseballLineupBatterCount: nil,
            designatedHitterID: nil,
            designatedHitterForID: nil,
            basketballUsesExplicitStartingLineup: false,
            basketballStartingLineupIDs: [:],
            basketballCourtLineupIDsByPeriod: [:],
            preGameNotes: "",
            postGameNotes: "",
            coachNotes: "",
            selectedSport: sport
        )
    }

    // Captures the currently selected team's roster, lineup, notes, and inning data.
    func currentTeamSnapshot(for sport: SportType? = nil) -> TeamSnapshot {
        let sport = sport ?? selectedSport
        // Make sure any visible inning edits are included in the snapshot.
        saveCurrentInningState()
        // Store only team-specific state here; global display settings stay in AppState.
        return TeamSnapshot(
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
            selectedSport: sport
        )
    }

    // Applies one team's saved snapshot into the active view-model properties.
    func applyTeamSnapshot(_ snapshot: TeamSnapshot) {
        // Restore roster, coaches, defensive assignments, batting order, notes, and sport state.
        players = snapshot.players
        coaches = snapshot.coaches ?? []
        pitcherID = snapshot.pitcherID
        catcherID = snapshot.catcherID
        lineup = snapshot.lineupIDs
        // Keep restored inning selection inside the currently configured inning range.
        selectedInning = min(max(snapshot.selectedInning, 1), numberOfInnings)
        inningLineups = snapshot.inningLineupIDs
        inningPitcherIDs = snapshot.inningPitcherIDs
        inningCatcherIDs = snapshot.inningCatcherIDs
        battingOrderIDs = snapshot.battingOrderIDs
        baseballLineupBatterCount = snapshot.baseballLineupBatterCount
        designatedHitterID = snapshot.designatedHitterID
        designatedHitterForID = snapshot.designatedHitterForID
        basketballUsesExplicitStartingLineup = snapshot.basketballUsesExplicitStartingLineup ?? false
        basketballStartingLineupIDs = snapshot.basketballStartingLineupIDs ?? [:]
        basketballCourtLineupIDsByPeriod = snapshot.basketballCourtLineupIDsByPeriod ?? [:]
        preGameNotes = snapshot.preGameNotes ?? ""
        postGameNotes = snapshot.postGameNotes ?? ""
        coachNotes = snapshot.coachNotes ?? ""
        // Sport selection is owned by the surrounding sport-state switch, not by individual team snapshots.

        // Ensure the active lineup matches the selected inning's saved lineup.
        if inningLineups[selectedInning] == nil {
            inningLineups[selectedInning] = lineup
        } else {
            lineup = inningLineups[selectedInning] ?? [:]
        }

        // Restore pitcher/catcher from inning-specific values when they exist.
        pitcherID = inningPitcherIDs[selectedInning] ?? snapshot.pitcherID
        catcherID = inningCatcherIDs[selectedInning] ?? snapshot.catcherID
        // Reconcile batting order IDs with the restored player list.
        syncBattingOrder()
    }
}
