// Created by Rich Morris on 5/5/26.
// Lineup Changer
// LineupViewModel+ExportSanitizing.swift
//
//
//
// Helpers that remove imported GameChanger data from share/export payloads.
import Foundation

// MARK: - Export Sanitizing Helpers
extension LineupViewModel {
    // Returns a copy of a player with GameChanger stats removed.
    // This keeps shared app/player exports focused on lineup data instead of imported stats.
    func playerWithoutGameChangerStats(_ player: Player) -> Player {
        // Work on a copy so the in-memory player keeps its stats.
        var copy = player
        copy.gameChangerStats = nil
        copy.basketballGameChangerStats = nil
        return copy
    }

    // Removes GameChanger stats from every player stored in a field-position lineup.
    func lineupWithoutGameChangerStats(_ lineup: [FieldPosition: Player]) -> [FieldPosition: Player] {
        Dictionary(uniqueKeysWithValues: lineup.map { position, player in
            (position, playerWithoutGameChangerStats(player))
        })
    }

    // Removes GameChanger stats from every inning's stored lineup.
    func inningLineupsWithoutGameChangerStats(_ lineups: [Int: [FieldPosition: Player]]) -> [Int: [FieldPosition: Player]] {
        Dictionary(uniqueKeysWithValues: lineups.map { inning, lineup in
            (inning, lineupWithoutGameChangerStats(lineup))
        })
    }

    // Builds a sanitized team snapshot for export.
    // Coaches are intentionally omitted and player stats are stripped from all lineup data.
    func teamSnapshotWithoutGameChangerStats(_ snapshot: TeamSnapshot) -> TeamSnapshot {
        TeamSnapshot(
            players: snapshot.players.map { playerWithoutGameChangerStats($0) },
            coaches: [],
            pitcherID: snapshot.pitcherID,
            catcherID: snapshot.catcherID,
            lineup: lineupWithoutGameChangerStats(snapshot.lineup),
            lineupIDs: snapshot.lineupIDs,
            selectedInning: snapshot.selectedInning,
            inningLineups: inningLineupsWithoutGameChangerStats(snapshot.inningLineups),
            inningLineupIDs: snapshot.inningLineupIDs,
            inningPitcherIDs: snapshot.inningPitcherIDs,
            inningCatcherIDs: snapshot.inningCatcherIDs,
            battingOrderIDs: snapshot.battingOrderIDs,
            baseballLineupBatterCount: snapshot.baseballLineupBatterCount,
            designatedHitterID: snapshot.designatedHitterID,
            designatedHitterForID: snapshot.designatedHitterForID,
            preGameNotes: snapshot.preGameNotes,
            postGameNotes: snapshot.postGameNotes
        )
    }

    // Removes GameChanger stats from every team snapshot stored for a sport.
    func sportTeamStateWithoutGameChangerStats(_ state: SportTeamState) -> SportTeamState {
        SportTeamState(
            selectedTeamIndex: state.selectedTeamIndex,
            teamNames: state.teamNames,
            teamSnapshots: state.teamSnapshots.map { teamSnapshotWithoutGameChangerStats($0) },
            hasCustomTeamNames: state.hasCustomTeamNames
        )
    }
}
