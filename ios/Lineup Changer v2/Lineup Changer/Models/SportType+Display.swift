// Created by Rich Morris on 5/5/26.
// Lineup Changer
// SportType+Display.swift
//
//
//
import Foundation

extension SportType {
    var settingsIconName: String {
        switch self {
        case .baseballSoftball:
            return "baseball"
        case .basketball:
            return "basketball"
        case .football:
            return "football"
        case .volleyball:
            return "volleyball"
        case .soccer:
            return "soccerball"
        }
    }

    var launchSelectionIcon: String {
        switch self {
        case .baseballSoftball:
            return "⚾️"
        case .basketball:
            return "🏀"
        case .football:
            return "🏈"
        case .volleyball:
            return "🏐"
        case .soccer:
            return "⚽️"
        }
    }

    var playingSurfaceTitle: String {
        switch self {
        case .basketball, .volleyball:
            return "Court"
        case .baseballSoftball, .football, .soccer:
            return "Field"
        }
    }

    var playingSurfaceIconName: String {
        switch self {
        case .baseballSoftball:
            return "baseball.diamond.bases"
        case .basketball:
            return "basketball.fill"
        case .football:
            return "football.fill"
        case .volleyball:
            return "volleyball.fill"
        case .soccer:
            return "soccerball"
        }
    }

    var fieldTabTitle: String {
        playingSurfaceTitle
    }

    var fieldTabIconName: String {
        playingSurfaceIconName
    }

    var playingSurfaceAssetName: String? {
        switch self {
        case .baseballSoftball:
            return nil
        case .basketball:
            return "BBallCourtView"
        case .football:
            return "Football_Field_View"
        case .volleyball:
            return "Volleyball_Court_View"
        case .soccer:
            return "Soccer_Field_View"
        }
    }
}
