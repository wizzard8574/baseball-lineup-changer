// Created by Rich Morris on 5/5/26.
// Lineup Changer
// LineupViewModel+Coaches.swift
//
//
//
// Coach-related LineupViewModel functionality.
// This extension manages coach creation, editing, and deletion while keeping
// coach persistence logic centralized through the shared save() workflow.
import Foundation
import SwiftUI
import UIKit
import Combine

// MARK: - Coach Management
extension LineupViewModel {

    // MARK: - Create Coach
    // Adds a new coach after trimming whitespace and validating the name.
    @discardableResult
    func addCoach(name: String) -> Coach? {
        // Ignore blank or whitespace-only coach names.
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // New coaches start with empty number, cell, and role values.
        let coach = Coach(name: trimmed)
        coaches.append(coach)
        save()
        return coach
    }

    // MARK: - Update Coach Fields
    // Updates the saved coach name after trimming whitespace.
    func updateCoachName(coachID: UUID, newName: String) {
        // Prevent saving empty coach names.
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let index = coaches.firstIndex(where: { $0.id == coachID }) else { return }
        // Update the matching coach record in place.
        coaches[index].name = trimmed
        save()
    }

    // Updates the coach jersey/staff number.
    func updateCoachNumber(coachID: UUID, newNumber: String) {
        // Store a cleaned version of the entered number.
        let trimmed = newNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let index = coaches.firstIndex(where: { $0.id == coachID }) else { return }
        coaches[index].number = trimmed
        save()
    }

    // Updates the coach cell phone number.
    func updateCoachCell(coachID: UUID, newCell: String) {
        // Remove accidental leading/trailing spaces from imported or typed values.
        let trimmed = newCell.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let index = coaches.firstIndex(where: { $0.id == coachID }) else { return }
        coaches[index].cell = trimmed
        save()
    }

    // Updates the coach role label.
    func updateCoachRole(coachID: UUID, newRole: String) {
        // Normalize the stored role text.
        let trimmed = newRole.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let index = coaches.firstIndex(where: { $0.id == coachID }) else { return }
        coaches[index].role = trimmed
        save()
    }

    // MARK: - Delete Coach
    // Removes the matching coach from the current roster.
    func deleteCoach(coachID: UUID) {
        // removeAll safely handles missing IDs without throwing errors.
        coaches.removeAll { $0.id == coachID }
        save()
    }
}
