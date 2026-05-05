//
//  LineupViewModel+Coaches.swift
//  Lineup Changer
//
//  Created by Rich Morris on 5/3/26.
//

import Foundation
import SwiftUI
import UIKit
import Combine

extension LineupViewModel {

@discardableResult
func addCoach(name: String) -> Coach? {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }

    let coach = Coach(name: trimmed)
    coaches.append(coach)
    save()
    return coach
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

func updateCoachRole(coachID: UUID, newRole: String) {
    let trimmed = newRole.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let index = coaches.firstIndex(where: { $0.id == coachID }) else { return }
    coaches[index].role = trimmed
    save()
}

func deleteCoach(coachID: UUID) {
    coaches.removeAll { $0.id == coachID }
    save()
}
}
