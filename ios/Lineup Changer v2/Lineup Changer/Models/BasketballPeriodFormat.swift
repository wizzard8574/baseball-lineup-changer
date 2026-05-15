// Created by Rich Morris on 5/14/26.
// Lineup Changer
// BasketballPeriodFormat.swift
//
//
//
import Foundation

// MARK: - Basketball Period Format
enum BasketballPeriodFormat: String, Codable, CaseIterable, Identifiable {
    case quarters
    case halves

    var id: String { rawValue }

    var periodCount: Int {
        switch self {
        case .quarters:
            return 4
        case .halves:
            return 2
        }
    }
}
