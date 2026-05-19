//
//  AudioModels.swift
//  Lineup Changer Catchercom
//
//  Created by Rich Morris on 5/18/26.
//
import SwiftUI
import Foundation

// MARK: - Pitch Calls

enum CatcherPitch: String, CaseIterable, Identifiable {
    case fastball
    case curveball
    case change
    case splitter
    case cutter

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fastball:
            return "Fastball"
        case .curveball:
            return "Curveball"
        case .change:
            return "Change"
        case .splitter:
            return "Splitter"
        case .cutter:
            return "Cutter"
        }
    }
}

// MARK: - Location Calls

enum CatcherLocation: String, CaseIterable, Identifiable {
    case up
    case down
    case out
    case `in`
    case middle

    var id: String { rawValue }

    var title: String {
        switch self {
        case .up:
            return "Up"
        case .down:
            return "Down"
        case .out:
            return "Out"
        case .in:
            return "In"
        case .middle:
            return "Middle"
        }
    }
}

// MARK: - Number Signs

enum CatcherNumberSign: String, CaseIterable, Identifiable {
    case one = "1"
    case two = "2"
    case twentyTwo = "22"
    case three = "3"
    case thirtyThree = "33"

    var id: String { rawValue }
    var title: String { rawValue }
}
