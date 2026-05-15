// Created by Rich Morris on 5/5/26.
// Lineup Changer
// MainTab+Display.swift
//
//
//
import Foundation

extension MainTab {
    func title(for sport: SportType) -> String {
        switch self {
        case .field:
            return sport.fieldTabTitle
        case .lineup:
            return "Lineup"
        case .players:
            return "Players"
        case .notes:
            return "Notes"
        case .settings:
            return "Settings"
        }
    }

    func iconName(for sport: SportType) -> String {
        switch self {
        case .field:
            return sport.fieldTabIconName
        case .lineup:
            return "list.number"
        case .players:
            return "person.3"
        case .notes:
            return "note.text"
        case .settings:
            return "gearshape"
        }
    }
}
