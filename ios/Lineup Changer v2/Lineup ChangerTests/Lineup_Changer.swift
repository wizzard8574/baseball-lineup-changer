import Foundation
import Testing
@testable import Lineup_Changer

@MainActor
struct LineupChangerTests {

    @Test func exportedCurrentAppStateImportsIntoFreshViewModel() throws {
        let playerID = UUID()
        let player = Player(id: playerID, name: "Riley Adams", number: "12")
        let exportingViewModel = makeViewModel()
        exportingViewModel.players = [player]
        exportingViewModel.battingOrderIDs = [playerID]
        exportingViewModel.lineup = [.firstBase: playerID]
        exportingViewModel.inningLineups = [1: [.firstBase: playerID]]

        let data = exportingViewModel.exportAppStateData()
        let decodedState = try JSONDecoder().decode(AppState.self, from: data)
        #expect(decodedState.lineupIDs[.firstBase] == playerID)
        #expect(decodedState.inningLineupIDs[1]?[.firstBase] == playerID)
        #expect(decodedState.teamSnapshots.count == 2)

        let importingViewModel = makeViewModel()
        try importingViewModel.importAppStateData(data)

        #expect(importingViewModel.players.map(\.name) == ["Riley Adams"])
        #expect(importingViewModel.battingOrderIDs == [playerID])
        #expect(importingViewModel.resolvedLineup[.firstBase]?.number == "12")
    }

    @Test func viewModelPersistsToInjectedUserDefaults() {
        let userDefaults = makeUserDefaults()
        let viewModel = LineupViewModel(userDefaults: userDefaults)

        viewModel.addPlayer(name: "  Jordan Lee  ")

        let restoredViewModel = LineupViewModel(userDefaults: userDefaults)
        #expect(restoredViewModel.players.map(\.name) == ["Jordan Lee"])
        #expect(restoredViewModel.battingOrderIDs == restoredViewModel.players.map(\.id))
    }

    @Test func switchingSportsUsesSeparateTeamSlots() {
        let viewModel = makeViewModel()
        let baseballPlayer = Player(name: "Baseball Player")
        viewModel.players = [baseballPlayer]
        viewModel.battingOrderIDs = [baseballPlayer.id]
        viewModel.updateSelectedTeamName("Baseball Club")

        viewModel.selectSport(.basketball)

        #expect(viewModel.teamNames == ["Basketball Team 1", "Basketball Team 2"])
        #expect(viewModel.players.isEmpty)

        let basketballPlayer = Player(name: "Basketball Player")
        viewModel.players = [basketballPlayer]
        viewModel.battingOrderIDs = [basketballPlayer.id]
        viewModel.updateSelectedTeamName("Basketball Club")

        viewModel.selectSport(.baseballSoftball)

        #expect(viewModel.teamNames[0] == "Baseball Club")
        #expect(viewModel.players.map(\.name) == ["Baseball Player"])

        viewModel.selectSport(.basketball)

        #expect(viewModel.teamNames[0] == "Basketball Club")
        #expect(viewModel.players.map(\.name) == ["Basketball Player"])
    }

    @Test func basketballPositionRatingsPersistInAppState() {
        let defaults = makeUserDefaults()
        let player = Player(
            name: "Basketball Player",
            basketballPositionRatings: [.one: 1, .five: 5]
        )
        let viewModel = LineupViewModel(userDefaults: defaults)

        viewModel.selectSport(.basketball)
        viewModel.players = [player]
        viewModel.save()

        let restoredViewModel = LineupViewModel(userDefaults: defaults)
        restoredViewModel.selectSport(.basketball)

        #expect(restoredViewModel.players.first?.basketballPositionRatings[.one] == 1)
        #expect(restoredViewModel.players.first?.basketballPositionRatings[.five] == 5)
    }

    @Test func basketballPlayerNumberPersistsInAppState() {
        let defaults = makeUserDefaults()
        let viewModel = LineupViewModel(userDefaults: defaults)

        viewModel.selectSport(.basketball)
        let player = viewModel.addPlayer(name: "Basketball Player")!
        viewModel.updatePlayerNumber(playerID: player.id, newNumber: "23")

        let restoredViewModel = LineupViewModel(userDefaults: defaults)
        restoredViewModel.selectSport(.basketball)

        #expect(restoredViewModel.players.first?.name == "Basketball Player")
        #expect(restoredViewModel.players.first?.number == "23")
    }

    @Test func basketballPlayersPersistWithDefaultTeamNamesWhenSwitchingSports() {
        let viewModel = makeViewModel()

        viewModel.selectSport(.basketball)
        viewModel.addPlayer(name: "Basketball Player")

        #expect(viewModel.teamNames == ["Basketball Team 1", "Basketball Team 2"])
        #expect(viewModel.players.map(\.name) == ["Basketball Player"])

        viewModel.selectSport(.baseballSoftball)
        viewModel.selectSport(.basketball)

        #expect(viewModel.teamNames == ["Basketball Team 1", "Basketball Team 2"])
        #expect(viewModel.players.map(\.name) == ["Basketball Player"])
    }

    @Test func basketballCoachesPersistPerTeamWhenSwitchingSports() {
        let viewModel = makeViewModel()

        viewModel.selectSport(.basketball)
        viewModel.addCoach(name: "Team One Coach")

        viewModel.selectTeam(1)
        #expect(viewModel.coaches.isEmpty)

        viewModel.addCoach(name: "Team Two Coach")
        viewModel.selectSport(.baseballSoftball)
        viewModel.addCoach(name: "Baseball Coach")
        viewModel.selectSport(.basketball)

        #expect(viewModel.selectedTeamIndex == 1)
        #expect(viewModel.coaches.map(\.name) == ["Team Two Coach"])

        viewModel.selectTeam(0)
        #expect(viewModel.coaches.map(\.name) == ["Team One Coach"])
    }

    @Test func basketballLineupAssignsBestRatedPlayersToStartingPositions() {
        let viewModel = makeViewModel()
        let players = [
            Player(name: "Bench", number: "9", basketballPositionRatings: [.one: 5, .two: 5, .three: 5, .four: 5, .five: 5]),
            Player(name: "Point", number: "1", basketballPositionRatings: [.one: 1]),
            Player(name: "Guard", number: "2", basketballPositionRatings: [.two: 1]),
            Player(name: "Wing", number: "3", basketballPositionRatings: [.three: 1]),
            Player(name: "Forward", number: "4", basketballPositionRatings: [.four: 1]),
            Player(name: "Center", number: "5", basketballPositionRatings: [.five: 1])
        ]

        viewModel.selectSport(.basketball)
        viewModel.players = players
        viewModel.battingOrderIDs = players.map(\.id)
        viewModel.assignBestBasketballLineup()

        #expect(viewModel.basketballStartingLineupPlayers.map(\.name) == ["Point", "Guard", "Wing", "Forward", "Center"])
        #expect(viewModel.basketballBenchPlayers.map(\.name) == ["Bench"])
    }

    @Test func basketballLineupMovesPlayersBetweenStartingLineupAndBench() {
        let viewModel = makeViewModel()
        let players = (1...6).map { Player(name: "Player \($0)", number: "\($0)") }

        viewModel.selectSport(.basketball)
        viewModel.players = players
        viewModel.battingOrderIDs = players.map(\.id)

        viewModel.moveBasketballLineupPlayer(playerID: players[5].id, toStartingIndex: 0)
        #expect(viewModel.basketballStartingLineupPlayers.map(\.name) == ["Player 6", "Player 1", "Player 2", "Player 3", "Player 4"])
        #expect(viewModel.basketballBenchPlayers.map(\.name) == ["Player 5"])

        viewModel.moveBasketballLineupPlayerToBench(playerID: players[5].id)
        #expect(viewModel.basketballStartingLineupPlayers.map(\.name) == ["Player 1", "Player 2", "Player 3", "Player 4", "Player 5"])
        #expect(viewModel.basketballBenchPlayers.map(\.name) == ["Player 6"])
    }

    @Test func clearBasketballLineupMovesStartersToBenchAndAllowsRefill() {
        let viewModel = makeViewModel()
        let players = (1...6).map {
            Player(name: "Player \($0)", number: "\($0)", basketballPositionRatings: [.one: 1, .two: 1, .three: 1, .four: 1, .five: 1])
        }

        viewModel.selectSport(.basketball)
        viewModel.players = players
        viewModel.battingOrderIDs = players.map(\.id)

        #expect(viewModel.basketballStartingLineupPlayers.map(\.name) == ["Player 1", "Player 2", "Player 3", "Player 4", "Player 5"])
        #expect(viewModel.basketballBenchPlayers.map(\.name) == ["Player 6"])

        viewModel.clearBasketballLineupToBench()

        #expect(viewModel.basketballStartingLineupPlayers.isEmpty)
        #expect(viewModel.basketballBenchPlayers.map(\.name) == (1...6).map { "Player \($0)" })

        let replacement = viewModel.forceReplaceBasketballStarter(at: .three, with: players[2].id)

        #expect(replacement?.incoming.name == "Player 3")
        #expect(replacement?.replaced == nil)
        #expect(viewModel.basketballStartingPlayer(for: .three)?.name == "Player 3")
        #expect(viewModel.basketballBenchPlayers.map(\.name) == ["Player 1", "Player 2", "Player 4", "Player 5", "Player 6"])

        viewModel.moveBasketballLineupPlayerToBench(playerID: players[2].id)

        #expect(viewModel.basketballStartingLineupPlayers.isEmpty)
        #expect(viewModel.basketballBenchPlayers.map(\.name) == (1...6).map { "Player \($0)" })
    }

    @Test func basketballCourtDisplaySettingsPersistInAppState() throws {
        let viewModel = makeViewModel()
        viewModel.selectSport(.basketball)
        viewModel.showRatingsOnCourt = false
        viewModel.showAssignedBasketballLineup = false
        viewModel.showBasketballBenchOnCourt = false
        viewModel.showFullNameAndNumberInBasketball = false
        viewModel.basketballPeriodFormat = .halves

        let data = try JSONEncoder().encode(viewModel.currentAppState())
        let decodedState = try JSONDecoder().decode(AppState.self, from: data)

        #expect(decodedState.showRatingsOnCourt == false)
        #expect(decodedState.showAssignedBasketballLineup == false)
        #expect(decodedState.showBasketballBenchOnCourt == false)
        #expect(decodedState.showFullNameAndNumberInBasketball == false)
        #expect(decodedState.basketballPeriodFormat == .halves)

        let restoredViewModel = makeViewModel()
        restoredViewModel.applyAppState(decodedState)

        #expect(restoredViewModel.selectedSport == .basketball)
        #expect(restoredViewModel.showRatingsOnCourt == false)
        #expect(restoredViewModel.showAssignedBasketballLineup == false)
        #expect(restoredViewModel.showBasketballBenchOnCourt == false)
        #expect(restoredViewModel.showFullNameAndNumberInBasketball == false)
        #expect(restoredViewModel.basketballPeriodFormat == .halves)
    }

    @Test func basketballPeriodFormatProvidesExpectedPeriodCounts() {
        #expect(BasketballPeriodFormat.quarters.periodCount == 4)
        #expect(BasketballPeriodFormat.halves.periodCount == 2)
    }

    @Test func applyingStateWithoutSportTeamStatesDoesNotCopyBaseballTeamsToBasketball() {
        let savedViewModel = makeViewModel()
        savedViewModel.updateSelectedTeamName("Headlines 12u Gold")
        var savedState = savedViewModel.currentAppState()
        savedState.selectedSport = .basketball
        savedState.sportTeamStates = [:]

        let restoredViewModel = makeViewModel()
        restoredViewModel.applyAppState(savedState)

        #expect(restoredViewModel.selectedSport == .basketball)
        #expect(restoredViewModel.teamNames == ["Basketball Team 1", "Basketball Team 2"])

        restoredViewModel.selectSport(.baseballSoftball)

        #expect(restoredViewModel.teamNames[0] == "Headlines 12u Gold")
    }

    @Test func applyingStateWithCopiedBasketballNamesResetsBasketballTeams() {
        let savedViewModel = makeViewModel()
        savedViewModel.updateSelectedTeamName("Headlines 12u Gold")
        var savedState = savedViewModel.currentAppState()
        savedState.selectedSport = .basketball
        savedState.sportTeamStates[.basketball] = SportTeamState(
            selectedTeamIndex: 0,
            teamNames: ["Headlines 12u Gold", "Team 2"],
            teamSnapshots: savedState.teamSnapshots
        )

        let restoredViewModel = makeViewModel()
        restoredViewModel.applyAppState(savedState)

        #expect(restoredViewModel.selectedSport == .basketball)
        #expect(restoredViewModel.teamNames == ["Basketball Team 1", "Basketball Team 2"])
    }

    @Test func switchingToCopiedBasketballStateResetsBasketballTeams() {
        let viewModel = makeViewModel()
        viewModel.updateSelectedTeamName("Headlines 12u Gold")
        viewModel.sportTeamStates[.basketball] = SportTeamState(
            selectedTeamIndex: 0,
            teamNames: ["Headlines 12u Gold", "Team 2"],
            teamSnapshots: [
                viewModel.currentTeamSnapshot(for: .baseballSoftball),
                viewModel.emptyTeamSnapshot(for: .baseballSoftball)
            ]
        )

        viewModel.selectSport(.basketball)

        #expect(viewModel.teamNames == ["Basketball Team 1", "Basketball Team 2"])
        #expect(viewModel.sportTeamStates[.basketball]?.teamNames == ["Basketball Team 1", "Basketball Team 2"])
    }

    @Test func rosterBatOffSplitsNineBatterLineupBenchAndMovesPlayers() {
        let viewModel = makeViewModel()
        let players = (1...11).map { Player(name: "Player \($0)", number: "\($0)") }
        viewModel.players = players
        viewModel.battingOrderIDs = players.map(\.id)

        #expect(viewModel.baseballUsesNineBatterAndDH)
        #expect(viewModel.baseballDisplayedBatters.map(\.name) == (1...9).map { "Player \($0)" })
        #expect(viewModel.baseballBenchBatters.map(\.name) == ["Player 10", "Player 11"])

        viewModel.moveBatter(playerID: players[10].id, toBattingOrderIndex: 0)
        #expect(viewModel.baseballDisplayedBatters.map(\.name) == (1...9).map { "Player \($0)" })
        #expect(viewModel.baseballBenchBatters.map(\.name) == ["Player 10", "Player 11"])
        #expect(viewModel.baseballLineupLimitWarningText == "You can't add more than 9 to the lineup")

        viewModel.moveBatterToBench(playerID: players[0].id)
        #expect(viewModel.baseballDisplayedBatters.map(\.name) == (2...9).map { "Player \($0)" })
        #expect(viewModel.baseballBenchBatters.map(\.name) == ["Player 1", "Player 10", "Player 11"])

        viewModel.moveBatter(playerID: players[10].id, toBattingOrderIndex: 0)
        #expect(viewModel.baseballDisplayedBatters.map(\.name) == ["Player 11"] + (2...9).map { "Player \($0)" })
        #expect(viewModel.baseballBenchBatters.map(\.name) == ["Player 1", "Player 10"])

        #expect(viewModel.forceReplaceBaseballBatter(atBattingOrderIndex: 0, with: players[9].id))
        #expect(viewModel.baseballDisplayedBatters.map(\.name) == ["Player 10"] + (2...9).map { "Player \($0)" })
        #expect(viewModel.baseballBenchBatters.map(\.name) == ["Player 1", "Player 11"])
    }

    @Test func rosterBatOnDisplaysFullLineupWithoutBenchOrDHRestrictions() {
        let viewModel = makeViewModel()
        let players = (1...11).map { Player(name: "Player \($0)", number: "\($0)") }
        viewModel.players = players
        viewModel.battingOrderIDs = players.map(\.id)
        viewModel.showOnlyNineBattersAndDH = true

        #expect(viewModel.baseballUsesRosterBat)
        #expect(viewModel.baseballDisplayedBatters.map(\.name) == (1...11).map { "Player \($0)" })
        #expect(viewModel.baseballBenchBatters.isEmpty)

        viewModel.moveBatter(playerID: players[10].id, toBattingOrderIndex: 0)
        #expect(Array(viewModel.baseballDisplayedBatters.map(\.name).prefix(3)) == ["Player 11", "Player 1", "Player 2"])
        #expect(viewModel.baseballLineupLimitWarningText == nil)
    }

    @Test func nineBatterAndDHCandidatesFollowBattingOrderChanges() {
        let viewModel = makeViewModel()
        let players = (1...11).map { Player(name: "Player \($0)", number: "\($0)") }
        viewModel.players = players
        viewModel.battingOrderIDs = players.map(\.id)

        #expect(viewModel.designatedHitterCandidates.map(\.name) == ["Player 10", "Player 11"])
        #expect(viewModel.designatedHitterForCandidates.map(\.name) == (1...9).map { "Player \($0)" })

        viewModel.designatedHitterID = players[9].id
        viewModel.designatedHitterForID = players[0].id
        #expect(viewModel.forceReplaceBaseballBatter(atBattingOrderIndex: 0, with: players[9].id))

        #expect(viewModel.designatedHitterID == nil)
        #expect(viewModel.designatedHitterForID == nil)
        #expect(viewModel.designatedHitterCandidates.map(\.name) == ["Player 1", "Player 11"])
        #expect(Array(viewModel.designatedHitterForCandidates.map(\.name).prefix(2)) == ["Player 10", "Player 2"])
    }

    @Test func designatedHitterDisplaysInSelectedLineupSpot() {
        let viewModel = makeViewModel()
        let players = (1...11).map { Player(name: "Player \($0)", number: "\($0)") }
        viewModel.players = players
        viewModel.battingOrderIDs = players.map(\.id)
        viewModel.designatedHitterID = players[9].id
        viewModel.designatedHitterForID = players[2].id

        #expect(viewModel.baseballDisplayedBatters.map(\.name) == (1...9).map { "Player \($0)" })
        #expect(viewModel.baseballDisplayedBattersForLineup.map(\.name) == ["Player 1", "Player 2", "Player 10", "Player 4", "Player 5", "Player 6", "Player 7", "Player 8", "Player 9"])
        #expect(viewModel.baseballBenchBatters.map(\.name) == ["Player 10", "Player 11"])
    }

    @Test func assignLineupUsesBestRatedAvailablePlayersWithoutDuplicates() {
        let viewModel = makeViewModel()
        let firstBasePlayer = Player(name: "Best First", positionRatings: [.firstBase: 1])
        let backupFirstBasePlayer = Player(name: "Backup First", positionRatings: [.firstBase: 3])
        let secondBasePlayer = Player(name: "Best Second", positionRatings: [.secondBase: 1])

        viewModel.players = [backupFirstBasePlayer, secondBasePlayer, firstBasePlayer]
        viewModel.battingOrderIDs = viewModel.players.map(\.id)

        viewModel.assignLineup()

        #expect(viewModel.lineup[.firstBase] == firstBasePlayer.id)
        #expect(viewModel.lineup[.secondBase] == secondBasePlayer.id)
        #expect(Set(viewModel.lineup.values).count == viewModel.lineup.count)
    }

    @Test func fallBallOptionsAreBlockedWhenRosterBatIsOff() {
        let viewModel = makeViewModel()

        viewModel.fallBallEnabled = true
        viewModel.fallBallRunRuleEnabled = true

        #expect(viewModel.baseballUsesNineBatterAndDH)
        #expect(!viewModel.fallBallEnabled)
        #expect(!viewModel.fallBallRunRuleEnabled)

        viewModel.showOnlyNineBattersAndDH = true
        viewModel.fallBallEnabled = true

        #expect(viewModel.baseballUsesRosterBat)
        #expect(viewModel.fallBallEnabled)
    }

    @Test func deletingAPlayerRemovesCurrentAndSavedAssignments() {
        let viewModel = makeViewModel()
        let pitcher = Player(name: "Pitcher")
        let catcher = Player(name: "Catcher")
        viewModel.players = [pitcher, catcher]
        viewModel.battingOrderIDs = viewModel.players.map(\.id)
        viewModel.pitcherID = pitcher.id
        viewModel.catcherID = catcher.id
        viewModel.lineup = [.pitcher: pitcher.id, .catcher: catcher.id]
        viewModel.inningLineups = [1: viewModel.lineup, 2: [.pitcher: pitcher.id]]
        viewModel.inningPitcherIDs = [1: pitcher.id, 2: pitcher.id]
        viewModel.inningCatcherIDs = [1: catcher.id]

        viewModel.deletePlayer(playerID: pitcher.id)

        #expect(viewModel.players.map(\.id) == [catcher.id])
        #expect(viewModel.pitcherID == nil)
        #expect(viewModel.catcherID == catcher.id)
        #expect(!viewModel.battingOrderIDs.contains(pitcher.id))
        #expect(viewModel.lineup.values.allSatisfy { $0 != pitcher.id })
        #expect(viewModel.inningLineups.values.flatMap(\.values).allSatisfy { $0 != pitcher.id })
        #expect(viewModel.inningPitcherIDs.isEmpty)
    }

    @Test func fallBallGenerationIsDeterministicWithInjectedRandomSource() {
        let firstViewModel = makeFallBallViewModel()
        let secondViewModel = makeFallBallViewModel()

        firstViewModel.assignLineup()
        secondViewModel.assignLineup()

        #expect(lineupNamesByInning(firstViewModel) == lineupNamesByInning(secondViewModel))
        #expect(firstViewModel.inningPitcherIDs == secondViewModel.inningPitcherIDs)
        #expect(Set(firstViewModel.inningPitcherIDs.values).count == 3)
    }

    @Test func playerEditsResolveThroughCurrentRoster() {
        let viewModel = makeViewModel()
        let player = Player(name: "Old Name", positionRatings: [.firstBase: 3])
        viewModel.players = [player]
        viewModel.battingOrderIDs = [player.id]
        viewModel.lineup = [.firstBase: player.id]
        viewModel.inningLineups = [1: [.firstBase: player.id], 2: [.firstBase: player.id]]

        viewModel.renamePlayer(playerID: player.id, newName: "New Name")
        viewModel.setRating(playerID: player.id, position: .firstBase, rating: 1)

        #expect(viewModel.resolvedLineup[.firstBase]?.name == "New Name")
        #expect(viewModel.resolvedLineup[.firstBase]?.positionRatings[.firstBase] == 1)
        #expect(viewModel.resolvedLineup(from: viewModel.inningLineups[1] ?? [:])[.firstBase]?.name == "New Name")
        #expect(viewModel.resolvedLineup(from: viewModel.inningLineups[2] ?? [:])[.firstBase]?.positionRatings[.firstBase] == 1)
    }

    @Test func savedStatePersistsLineupIDsAndRestoresFreshPlayerValues() {
        let playerID = UUID()
        let freshPlayer = Player(id: playerID, name: "Fresh Name", number: "7")
        let viewModel = makeViewModel()
        viewModel.players = [freshPlayer]
        viewModel.battingOrderIDs = [playerID]
        viewModel.lineup = [.firstBase: playerID]
        viewModel.inningLineups = [1: [.firstBase: playerID]]

        let state = viewModel.currentAppState()
        #expect(state.lineupIDs[.firstBase] == playerID)
        #expect(state.inningLineupIDs[1]?[.firstBase] == playerID)
        #expect(state.teamSnapshots[0].lineupIDs[.firstBase] == playerID)

        let restoredViewModel = makeViewModel()
        restoredViewModel.applyAppState(state)

        #expect(restoredViewModel.resolvedLineup[.firstBase]?.name == "Fresh Name")
        #expect(restoredViewModel.resolvedLineup[.firstBase]?.number == "7")
        #expect(restoredViewModel.resolvedLineup(from: restoredViewModel.inningLineups[1] ?? [:])[.firstBase]?.name == "Fresh Name")
    }

    private func makeViewModel(lineupRandomIndex: @escaping (Int) -> Int = { _ in 0 }) -> LineupViewModel {
        LineupViewModel(userDefaults: makeUserDefaults(), lineupRandomIndex: lineupRandomIndex)
    }

    private func makeUserDefaults() -> UserDefaults {
        let suiteName = "LineupChangerTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }

    private func makeFallBallViewModel() -> LineupViewModel {
        let viewModel = makeViewModel()
        let players = [
            testPlayer(uuidSuffix: "001", name: "Avery", isPitcher: true),
            testPlayer(uuidSuffix: "002", name: "Blake", isPitcher: true),
            testPlayer(uuidSuffix: "003", name: "Casey", isPitcher: true),
            testPlayer(uuidSuffix: "004", name: "Drew", isPitcher: false),
            testPlayer(uuidSuffix: "005", name: "Emerson", isPitcher: false),
            testPlayer(uuidSuffix: "006", name: "Finley", isPitcher: false),
            testPlayer(uuidSuffix: "007", name: "Gray", isPitcher: false),
            testPlayer(uuidSuffix: "008", name: "Hayden", isPitcher: false),
            testPlayer(uuidSuffix: "009", name: "Indigo", isPitcher: false)
        ]

        viewModel.players = players
        viewModel.battingOrderIDs = players.map(\.id)
        viewModel.catcherID = players[3].id
        viewModel.numberOfInnings = 3
        viewModel.showOnlyNineBattersAndDH = true
        viewModel.fallBallEnabled = true
        return viewModel
    }

    private func testPlayer(uuidSuffix: String, name: String, isPitcher: Bool) -> Player {
        var ratings = Dictionary(uniqueKeysWithValues: FieldPosition.autoAssignedPositions.map { ($0, 1) })
        if isPitcher {
            ratings[.pitcher] = 1
        }
        return Player(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000\(uuidSuffix)")!,
            name: name,
            positionRatings: ratings
        )
    }

    private func lineupNamesByInning(_ viewModel: LineupViewModel) -> [Int: [FieldPosition: String]] {
        viewModel.inningLineups.mapValues { lineup in
            viewModel.resolvedLineup(from: lineup).mapValues(\.name)
        }
    }
}
