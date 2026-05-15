import Foundation

extension LineupViewModel {
    func setBasketballRating(playerID: UUID, position: BasketballPosition, rating: Int) {
        guard let index = players.firstIndex(where: { $0.id == playerID }) else { return }
        players[index].basketballPositionRatings[position] = rating
        save()
    }

    func removeBasketballPosition(playerID: UUID, position: BasketballPosition) {
        guard let index = players.firstIndex(where: { $0.id == playerID }) else { return }
        players[index].basketballPositionRatings.removeValue(forKey: position)
        save()
    }
}
