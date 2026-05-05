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
    @Published var numberOfInnings: Int = LineupViewModel.loadSavedNumberOfInnings() {
        didSet {
            let clamped = min(max(numberOfInnings, 1), 12)
            if clamped != numberOfInnings { numberOfInnings = clamped }
            UserDefaults.standard.set(numberOfInnings, forKey: Self.numberOfInningsDefaultsKey)
        }
    }
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

    var teamSnapshots: [TeamSnapshot?] = [nil, nil]
    var isApplyingSavedState = false

    let saveKey = "YouthPositionRanker.appState.v3"

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

    
    

    var activePlayers: [Player] {
        players.filter { $0.status == .active || $0.status == .guest }
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

    private static let numberOfInningsDefaultsKey = "numberOfInnings"

    private static func loadSavedNumberOfInnings() -> Int {
        let saved = UserDefaults.standard.integer(forKey: numberOfInningsDefaultsKey)
        return (1...12).contains(saved) ? saved : 7
    }


}
