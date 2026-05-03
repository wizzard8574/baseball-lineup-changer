import Foundation
import SwiftUI
import UIKit
import Combine

// MARK: - ViewModel

@MainActor
final class LineupViewModel: ObservableObject {
    @Published var players: [Player] = []
    @Published var coaches: [Coach] = [] { didSet { save() } }
    @Published var pitcherID: UUID?
    @Published var catcherID: UUID?
    @Published var lineup: [FieldPosition: Player] = [:]
    @Published var selectedInning = 1
    @Published var inningLineups: [Int: [FieldPosition: Player]] = [:]
    @Published var inningPitcherIDs: [Int: UUID] = [:]
    @Published var inningCatcherIDs: [Int: UUID] = [:]
    @Published var showRatingsOnField = true { didSet { save() } }
    @Published var showAssignedLineupTable = true { didSet { save() } }
    // true = full name and number. false = first initial, last name, and number.
    @Published var showFullNameAndNumber = true { didSet { save() } }
    @Published var showBenchOnField = true { didSet { save() } }
    @Published var showOnlyNineBattersAndDH = false { didSet { save() } }
    @Published var showSlowSpeedBattingWarnings = true { didSet { save() } }
    @Published var fallBallEnabled = false {
        didSet {
            if !fallBallEnabled {
                fallBallYouthEnabled = false
            }
            save()
        }
    }
    @Published var fallBallYouthEnabled = false { didSet { save() } }
    @Published var battingOrderIDs: [UUID] = [] { didSet { save() } }
    @Published var designatedHitterID: UUID? { didSet { save() } }
    @Published var designatedHitterForID: UUID? { didSet { save() } }
    @Published var selectedTeamIndex = 0
    @Published var teamNames = ["Team 1", "Team 2"] { didSet { save() } }
    @Published var preGameNotes: String = "" { didSet { save() } }
    @Published var postGameNotes: String = "" { didSet { save() } }
    @Published var coachNotes: String = "" { didSet { save() } }
    @Published var selectedSport: SportType = .baseballSoftball { didSet { save() } }
    // Removed GameChanger properties

    private var teamSnapshots: [TeamSnapshot?] = [nil, nil]
    private var isApplyingSavedState = false

    private let saveKey = "YouthPositionRanker.appState.v3"

    init() {
        load()
    }

    var selectedTeamName: String {
        guard teamNames.indices.contains(selectedTeamIndex) else { return "Team \(selectedTeamIndex + 1)" }
        return teamNames[selectedTeamIndex]
    }

    func selectTeam(_ index: Int) {
        let safeIndex = min(max(index, 0), 1)
        guard safeIndex != selectedTeamIndex else { return }

        teamSnapshots[selectedTeamIndex] = currentTeamSnapshot()
        selectedTeamIndex = safeIndex

        if let snapshot = teamSnapshots[safeIndex] {
            applyTeamSnapshot(snapshot)
        } else {
            applyTeamSnapshot(emptyTeamSnapshot())
        }

        save()
    }

    func updateSelectedTeamName(_ newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, teamNames.indices.contains(selectedTeamIndex) else { return }
        teamNames[selectedTeamIndex] = trimmed
        save()
    }

    private func emptyTeamSnapshot() -> TeamSnapshot {
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

    private func currentTeamSnapshot() -> TeamSnapshot {
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

    private func applyTeamSnapshot(_ snapshot: TeamSnapshot) {
        players = snapshot.players
        coaches = snapshot.coaches ?? []
        pitcherID = snapshot.pitcherID
        catcherID = snapshot.catcherID
        lineup = snapshot.lineup
        selectedInning = min(max(snapshot.selectedInning, 1), 9)
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

    func addPlayer(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let player = Player(name: trimmed)
        players.append(player)
        battingOrderIDs.append(player.id)
        save()
    }

    func addCoach(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        coaches.append(Coach(name: trimmed))
        save()
    }

    func updateCoachName(coachID: UUID, newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let index = coaches.firstIndex(where: { $0.id == coachID }) else { return }
        coaches[index].name = trimmed
        save()
    }

    func updateCoachNumber(coachID: UUID, newNumber: String) {
        let trimmed = newNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let index = coaches.firstIndex(where: { $0.id == coachID }) else { return }
        coaches[index].number = trimmed
        save()
    }

    func updateCoachCell(coachID: UUID, newCell: String) {
        let trimmed = newCell.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let index = coaches.firstIndex(where: { $0.id == coachID }) else { return }
        coaches[index].cell = trimmed
        save()
    }

    func deleteCoach(coachID: UUID) {
        coaches.removeAll { $0.id == coachID }
        save()
    }
    
    func updateCoachRole(coachID: UUID, newRole: String) {
        let trimmed = newRole.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let index = coaches.firstIndex(where: { $0.id == coachID }) else { return }
        coaches[index].role = trimmed
        save()
    }

    func deletePlayers(at offsets: IndexSet) {
        let deletedIDs = offsets.map { players[$0].id }
        players.remove(atOffsets: offsets)

        battingOrderIDs.removeAll { deletedIDs.contains($0) }
        if let designatedHitterID, deletedIDs.contains(designatedHitterID) { self.designatedHitterID = nil }
        if let designatedHitterForID, deletedIDs.contains(designatedHitterForID) { self.designatedHitterForID = nil }

        if let pitcherID, deletedIDs.contains(pitcherID) { self.pitcherID = nil }
        if let catcherID, deletedIDs.contains(catcherID) { self.catcherID = nil }

        lineup = lineup.filter { !deletedIDs.contains($0.value.id) }
        for inning in inningLineups.keys {
            inningLineups[inning] = inningLineups[inning]?.filter { !deletedIDs.contains($0.value.id) } ?? [:]
        }
        for inning in inningPitcherIDs.keys where deletedIDs.contains(inningPitcherIDs[inning]!) {
            inningPitcherIDs.removeValue(forKey: inning)
        }
        for inning in inningCatcherIDs.keys where deletedIDs.contains(inningCatcherIDs[inning]!) {
            inningCatcherIDs.removeValue(forKey: inning)
        }
        save()
    }

    func deletePlayer(playerID: UUID) {
        guard let index = players.firstIndex(where: { $0.id == playerID }) else { return }
        deletePlayers(at: IndexSet(integer: index))
    }

    func renamePlayer(playerID: UUID, newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let index = players.firstIndex(where: { $0.id == playerID }) else { return }

        players[index].name = trimmed
        save()
    }

    func updatePlayerNumber(playerID: UUID, newNumber: String) {
        let trimmed = newNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let index = players.firstIndex(where: { $0.id == playerID }) else { return }

        players[index].number = trimmed
        save()
    }
    
    func updatePlayerCell(playerID: UUID, newCell: String) {

        let trimmedCell = newCell.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let index = players.firstIndex(where: { $0.id == playerID }) else { return }

        players[index].cell = trimmedCell

        save()

    }

    func updatePlayerSpeed(playerID: UUID, speedRating: Int) {
        guard let index = players.firstIndex(where: { $0.id == playerID }) else { return }
        players[index].speedRating = speedRating
        save()
    }
    
    func updatePlayerNotes(playerID: UUID, notes: String) {
        guard let index = players.firstIndex(where: { $0.id == playerID }) else { return }
        players[index].notes = notes
        save()
    }


    func setPlayerStatus(playerID: UUID, status: PlayerStatus) {
        guard let index = players.firstIndex(where: { $0.id == playerID }) else { return }
        players[index].status = status

        if status != .active {
            lineup = lineup.filter { $0.value.id != playerID }

            for inning in inningLineups.keys {
                inningLineups[inning] = inningLineups[inning]?.filter { $0.value.id != playerID } ?? [:]
            }

            if pitcherID == playerID { pitcherID = nil }
            if catcherID == playerID { catcherID = nil }

            for inning in inningPitcherIDs.keys where inningPitcherIDs[inning] == playerID {
                inningPitcherIDs.removeValue(forKey: inning)
            }

            for inning in inningCatcherIDs.keys where inningCatcherIDs[inning] == playerID {
                inningCatcherIDs.removeValue(forKey: inning)
            }

            if designatedHitterID == playerID { designatedHitterID = nil }
            if designatedHitterForID == playerID { designatedHitterForID = nil }
        }

        saveCurrentInningState()
        save()
    }

    var activePlayers: [Player] {
        players.filter { $0.status == .active }
    }


    func setRating(playerID: UUID, position: FieldPosition, rating: Int) {
        guard let index = players.firstIndex(where: { $0.id == playerID }) else { return }
        players[index].positionRatings[position] = rating
        save()
    }

    func removePosition(playerID: UUID, position: FieldPosition) {
        guard let index = players.firstIndex(where: { $0.id == playerID }) else { return }
        players[index].positionRatings.removeValue(forKey: position)
        save()
    }

    func assignLineup() {
        if fallBallEnabled {
            assignFallBallLineups()
            return
        }

        var assignments: [FieldPosition: Player] = [:]
        var usedPlayerIDs = Set<UUID>()
        let eligiblePlayers = activePlayers

        if let pitcher = eligiblePlayers.first(where: { $0.id == pitcherID }) {
            assignments[.pitcher] = pitcher
            usedPlayerIDs.insert(pitcher.id)
        }

        if let catcher = eligiblePlayers.first(where: { $0.id == catcherID }), !usedPlayerIDs.contains(catcher.id) {
            assignments[.catcher] = catcher
            usedPlayerIDs.insert(catcher.id)
        }

        // Fills the remaining field positions using the best available rating.
        // 1 is best, 5 is worst.
        // Players are only considered for positions entered on their profile.
        for position in FieldPosition.autoAssignedPositions {
            let bestAvailable = eligiblePlayers
                .filter { player in
                    !usedPlayerIDs.contains(player.id) && player.positionRatings[position] != nil
                }
                .sorted { lhs, rhs in
                    let lhsRating = lhs.positionRatings[position] ?? 99
                    let rhsRating = rhs.positionRatings[position] ?? 99

                    if lhsRating == rhsRating {
                        return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                    }

                    return lhsRating < rhsRating
                }
                .first

            if let bestAvailable {
                assignments[position] = bestAvailable
                usedPlayerIDs.insert(bestAvailable.id)
            }
        }

        lineup = assignments
        saveCurrentInningState()
        copyCurrentInningForwardIfNeeded()
        save()
    }

    private func assignFallBallLineups() {
        guard !activePlayers.isEmpty else { return }

        var playCounts = Dictionary(uniqueKeysWithValues: activePlayers.map { ($0.id, 0) })
        var benchCounts = Dictionary(uniqueKeysWithValues: activePlayers.map { ($0.id, 0) })
        var generatedLineups: [Int: [FieldPosition: Player]] = [:]
        var generatedPitchers: [Int: UUID] = [:]
        var generatedCatchers: [Int: UUID] = [:]
        var usedFallBallPitcherIDs = Set<UUID>()

        for inning in 1...9 {
            let assignment = fallBallYouthEnabled
                ? randomYouthFallBallAssignment(playCounts: &playCounts, benchCounts: &benchCounts)
                : randomFallBallAssignment(playCounts: &playCounts, benchCounts: &benchCounts, usedPitcherIDs: &usedFallBallPitcherIDs)

            generatedLineups[inning] = assignment

            if let pitcher = assignment[.pitcher] {
                generatedPitchers[inning] = pitcher.id
            }

            if let catcher = assignment[.catcher] {
                generatedCatchers[inning] = catcher.id
            }
        }

        inningLineups = generatedLineups
        inningPitcherIDs = generatedPitchers
        inningCatcherIDs = generatedCatchers
        selectedInning = 1
        lineup = generatedLineups[1] ?? [:]
        pitcherID = generatedPitchers[1]
        catcherID = fallBallYouthEnabled ? generatedCatchers[1] : catcherID
        save()
    }

    private func randomFallBallAssignment(playCounts: inout [UUID: Int], benchCounts: inout [UUID: Int], usedPitcherIDs: inout Set<UUID>) -> [FieldPosition: Player] {
        var assignments: [FieldPosition: Player] = [:]
        var usedPlayerIDs = Set<UUID>()
        let eligiblePlayers = activePlayers

        let availablePitchers = eligiblePlayers.filter { $0.positionRatings[.pitcher] != nil }
        let pitcherCandidates = availablePitchers.filter { !usedPitcherIDs.contains($0.id) }
        let selectedPitcher = (pitcherCandidates.isEmpty ? availablePitchers : pitcherCandidates)
            .shuffled()
            .sorted { lhs, rhs in
                playCounts[lhs.id, default: 0] < playCounts[rhs.id, default: 0]
            }
            .first

        if let pitcher = selectedPitcher {
            assignments[.pitcher] = pitcher
            usedPlayerIDs.insert(pitcher.id)
            usedPitcherIDs.insert(pitcher.id)
            playCounts[pitcher.id, default: 0] += 1
        }

        if let catcher = eligiblePlayers.first(where: { $0.id == catcherID }), !usedPlayerIDs.contains(catcher.id) {
            assignments[.catcher] = catcher
            usedPlayerIDs.insert(catcher.id)
            playCounts[catcher.id, default: 0] += 1
        }

        for position in FieldPosition.autoAssignedPositions.shuffled() {
            let candidates = eligiblePlayers
                .filter { player in
                    !usedPlayerIDs.contains(player.id) && player.positionRatings[position] != nil
                }
                .sorted { lhs, rhs in
                    let lhsPlays = playCounts[lhs.id, default: 0]
                    let rhsPlays = playCounts[rhs.id, default: 0]

                    if lhsPlays == rhsPlays {
                        return Bool.random()
                    }

                    return lhsPlays < rhsPlays
                }

            if let selectedPlayer = candidates.first {
                assignments[position] = selectedPlayer
                usedPlayerIDs.insert(selectedPlayer.id)
                playCounts[selectedPlayer.id, default: 0] += 1
            }
        }

        updateBenchCounts(usedPlayerIDs: usedPlayerIDs, benchCounts: &benchCounts)
        return assignments
    }

    private func randomYouthFallBallAssignment(playCounts: inout [UUID: Int], benchCounts: inout [UUID: Int]) -> [FieldPosition: Player] {
        var assignments: [FieldPosition: Player] = [:]
        var usedPlayerIDs = Set<UUID>()
        let eligiblePlayers = activePlayers

        for position in FieldPosition.allCases.shuffled() {
            let candidates = eligiblePlayers
                .filter { !usedPlayerIDs.contains($0.id) }
                .sorted { lhs, rhs in
                    let lhsPlays = playCounts[lhs.id, default: 0]
                    let rhsPlays = playCounts[rhs.id, default: 0]

                    if lhsPlays == rhsPlays {
                        return Bool.random()
                    }

                    return lhsPlays < rhsPlays
                }

            if let selectedPlayer = candidates.first {
                assignments[position] = selectedPlayer
                usedPlayerIDs.insert(selectedPlayer.id)
                playCounts[selectedPlayer.id, default: 0] += 1
            }
        }

        updateBenchCounts(usedPlayerIDs: usedPlayerIDs, benchCounts: &benchCounts)
        return assignments
    }

    private func updateBenchCounts(usedPlayerIDs: Set<UUID>, benchCounts: inout [UUID: Int]) {
        for player in activePlayers where !usedPlayerIDs.contains(player.id) {
            benchCounts[player.id, default: 0] += 1
        }
    }

    func clearInning() {
        lineup = [:]
        pitcherID = nil
        catcherID = nil
        inningLineups[selectedInning] = [:]
        inningPitcherIDs.removeValue(forKey: selectedInning)
        inningCatcherIDs.removeValue(forKey: selectedInning)
        save()
    }

    func clearAllInnings() {
        lineup = [:]
        pitcherID = nil
        catcherID = nil
        inningLineups = [:]
        inningPitcherIDs = [:]
        inningCatcherIDs = [:]
        save()
    }

    func deleteAllPlayerData() {
        players = []
        coaches = []
        battingOrderIDs = []
        pitcherID = nil
        catcherID = nil
        lineup = [:]
        inningLineups = [:]
        inningPitcherIDs = [:]
        inningCatcherIDs = [:]
        designatedHitterID = nil
        designatedHitterForID = nil
        save()
    }
    
    func deleteAllPlayersOnly() {
        players.removeAll()
        pitcherID = nil
        catcherID = nil
        lineup.removeAll()
        inningLineups.removeAll()
        inningPitcherIDs.removeAll()
        inningCatcherIDs.removeAll()
        battingOrderIDs.removeAll()
        designatedHitterID = nil
        designatedHitterForID = nil
        save()
    }

    func setCurrentLineupForAllInnings() {
        saveCurrentInningState()

        for inning in 1...9 {
            inningLineups[inning] = lineup

            if let pitcherID {
                inningPitcherIDs[inning] = pitcherID
            } else {
                inningPitcherIDs.removeValue(forKey: inning)
            }

            if let catcherID {
                inningCatcherIDs[inning] = catcherID
            } else {
                inningCatcherIDs.removeValue(forKey: inning)
            }
        }

        save()
    }

    func selectInning(_ inning: Int) {
        saveCurrentInningState()
        selectedInning = min(max(inning, 1), 9)

        if inningLineups[selectedInning] == nil, selectedInning > 1 {
            inningLineups[selectedInning] = inningLineups[selectedInning - 1] ?? lineup
            inningPitcherIDs[selectedInning] = inningPitcherIDs[selectedInning - 1]
            inningCatcherIDs[selectedInning] = inningCatcherIDs[selectedInning - 1]
        }

        lineup = inningLineups[selectedInning] ?? [:]
        pitcherID = inningPitcherIDs[selectedInning]
        catcherID = inningCatcherIDs[selectedInning]
        save()
    }

    func saveCurrentInningState() {
        inningLineups[selectedInning] = lineup

        if let pitcherID {
            inningPitcherIDs[selectedInning] = pitcherID
        } else {
            inningPitcherIDs.removeValue(forKey: selectedInning)
        }

        if let catcherID {
            inningCatcherIDs[selectedInning] = catcherID
        } else {
            inningCatcherIDs.removeValue(forKey: selectedInning)
        }
    }

    func updatePitcher(_ playerID: UUID?) {
        pitcherID = playerID
        if catcherID == playerID { catcherID = nil }
        saveCurrentInningState()
        copyCurrentInningForwardIfNeeded()
        save()
    }

    func updateCatcher(_ playerID: UUID?) {
        catcherID = playerID
        if pitcherID == playerID { pitcherID = nil }
        saveCurrentInningState()
        copyCurrentInningForwardIfNeeded()
        save()
    }

    func updateFieldPosition(_ position: FieldPosition, playerID: UUID?) {
        if position == .pitcher {
            updatePitcher(playerID)
            if let playerID, let player = activePlayers.first(where: { $0.id == playerID }) {
                lineup[.pitcher] = player
            } else {
                lineup.removeValue(forKey: .pitcher)
            }
            saveCurrentInningState()
            copyCurrentInningForwardIfNeeded()
            save()
            return
        }

        if position == .catcher {
            updateCatcher(playerID)
            if let playerID, let player = activePlayers.first(where: { $0.id == playerID }) {
                lineup[.catcher] = player
            } else {
                lineup.removeValue(forKey: .catcher)
            }
            saveCurrentInningState()
            copyCurrentInningForwardIfNeeded()
            save()
            return
        }

        if let playerID {
            guard let player = activePlayers.first(where: { $0.id == playerID }) else { return }

            lineup = lineup.filter { existingPosition, existingPlayer in
                existingPosition == position || existingPlayer.id != playerID
            }
            lineup[position] = player
        } else {
            lineup.removeValue(forKey: position)
        }

        saveCurrentInningState()
        copyCurrentInningForwardIfNeeded()
        save()
    }

    /// Places a bench player into the field in the best open/rated position.
    func placeBenchPlayerInField(playerID: UUID) {
        guard let player = activePlayers.first(where: { $0.id == playerID }) else { return }

        lineup = lineup.filter { _, existingPlayer in
            existingPlayer.id != playerID
        }

        let ratedPositions = FieldPosition.autoAssignedPositions
            .filter { player.positionRatings[$0] != nil }
            .sorted { lhs, rhs in
                let lhsRating = player.positionRatings[lhs] ?? 99
                let rhsRating = player.positionRatings[rhs] ?? 99

                if lhsRating == rhsRating {
                    return lhs.rawValue < rhs.rawValue
                }

                return lhsRating < rhsRating
            }

        if let openRatedPosition = ratedPositions.first(where: { lineup[$0] == nil }) {
            lineup[openRatedPosition] = player
        } else if let bestRatedPosition = ratedPositions.first {
            lineup[bestRatedPosition] = player
        } else if let openPosition = FieldPosition.autoAssignedPositions.first(where: { lineup[$0] == nil }) {
            lineup[openPosition] = player
        } else if let fallbackPosition = FieldPosition.autoAssignedPositions.first {
            lineup[fallbackPosition] = player
        }

        saveCurrentInningState()
        copyCurrentInningForwardIfNeeded()
        save()
    }

    func copyCurrentInningForwardIfNeeded() {
        guard selectedInning < 9 else { return }

        for inning in (selectedInning + 1)...9 {
            if inningLineups[inning] == nil || inningLineups[inning]?.isEmpty == true {
                inningLineups[inning] = lineup
                inningPitcherIDs[inning] = pitcherID
                inningCatcherIDs[inning] = catcherID
            }
        }
    }

    func player(for id: UUID) -> Player? {
        players.first { $0.id == id }
    }

    func displayLabel(for player: Player) -> String {
        let nameParts = player.name.split(separator: " ").map(String.init)
        let lastName = nameParts.last ?? player.name
        let firstInitial = nameParts.first?.first.map { "\($0)." } ?? ""
        let initialLastName = firstInitial.isEmpty ? lastName : "\(firstInitial) \(lastName)"

        if showFullNameAndNumber {
            return player.number.isEmpty ? player.name : "#\(player.number) \(player.name)"
        }

        return player.number.isEmpty ? initialLastName : "#\(player.number) \(initialLastName)"
    }

    func syncBattingOrder() {
        let existingIDs = Set(players.map { $0.id })
        battingOrderIDs.removeAll { !existingIDs.contains($0) }

        for player in players where !battingOrderIDs.contains(player.id) {
            battingOrderIDs.append(player.id)
        }
        save()
    }

    func moveBatters(from source: IndexSet, to destination: Int) {
        syncBattingOrder()
        battingOrderIDs.move(fromOffsets: source, toOffset: destination)
        save()
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
}
