// Created by Rich Morris on 5/5/26.
// Lineup Changer
// Caoch.swift
//
//
//
import Foundation

// MARK: - Coach Model
// Coach contact/profile model used by coach lists and message/call actions.
struct Coach: Identifiable, Codable, Equatable , Hashable{
    // Stable identifier used for persistence and SwiftUI lists.
    let id: UUID
    // Coach profile and contact fields.
    var name: String
    var number: String
    var cell: String
    var role: String

    // Creates a coach with optional number, cell, and role values.
    init(id: UUID = UUID(), name: String, number: String = "", cell: String = "", role: String = "") {
        self.id = id
        self.name = name
        self.number = number
        self.cell = cell
        self.role = role
    }
}
