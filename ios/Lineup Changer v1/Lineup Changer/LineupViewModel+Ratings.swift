//
//  LineupViewModel+Ratings.swift
//  Lineup Changer
//
//  Created by Rich Morris on 5/3/26.
//

import Foundation
import SwiftUI
import UIKit
import Combine

extension LineupViewModel {
    
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
    
}
