// Created by Rich Morris on 5/5/26.
// Lineup Changer
// SportType.swift
//
//
//
import Foundation

// MARK: - Sport Type
// Sports supported or planned by the app.

enum SportType: String, CaseIterable, Identifiable, Codable {
    // Currently implemented sport mode.
    case baseballSoftball = "Baseball/Softball"
    case basketball = "Basketball"
    case football = "Football"
    case volleyball = "Volleyball"
    case soccer = "Soccer"

    // Allows SportType to be used directly in SwiftUI ForEach views.
    var id: String { rawValue }
}
