//
//  PlayModels.swift
//  Lineup Changer Catchercom
//
//  Created by Rich Morris on 5/18/26.
//
import SwiftUI

// MARK: - Play Category

struct PlayCategory: Identifiable, Equatable, Codable {
    // MARK: Properties

    let id: String
    let title: String
    var plays: [PlayCallItem]

    private static let storageKey = "catchercom.playCategories"
    private static let legacyPlayStorageKey = "catchercom.playOrder"
    private static let removedDefaultCategoryID = "general"

    // MARK: Factories

    static func custom(title: String) -> PlayCategory {
        PlayCategory(
            id: UUID().uuidString,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            plays: []
        )
    }

    // MARK: Persistence

    static func loadSavedCategories() -> [PlayCategory] {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let savedCategories = try? JSONDecoder().decode([PlayCategory].self, from: data),
           !savedCategories.isEmpty {
            // The old default "General" category was removed; filter it out if it exists in saved data.
            return savedCategories.filter { $0.id != removedDefaultCategoryID }
        }

        if let data = UserDefaults.standard.data(forKey: legacyPlayStorageKey),
           let legacyPlays = try? JSONDecoder().decode([PlayCallItem].self, from: data),
           !legacyPlays.isEmpty {
            // Legacy uncategorized plays are not shown because the current flow requires a user-created category.
            return []
        }

        return []
    }

    static func saveCategories(_ categories: [PlayCategory]) {
        let savedCategories = categories.filter { $0.id != removedDefaultCategoryID }
        guard let data = try? JSONEncoder().encode(savedCategories) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

// MARK: - Play Call

struct PlayCallItem: Identifiable, Equatable, Codable {
    // MARK: Properties

    let id: String
    let title: String
    let numbers: [String]

    // MARK: Factories

    static func custom(title: String, numbers: [String]) -> PlayCallItem {
        PlayCallItem(
            id: UUID().uuidString,
            title: title,
            numbers: cleanNumbers(numbers)
        )
    }

    static func edited(id: String, title: String, numbers: [String]) -> PlayCallItem {
        PlayCallItem(
            id: id,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            numbers: cleanNumbers(numbers)
        )
    }

    // MARK: Helpers

    private static func cleanNumbers(_ numbers: [String]) -> [String] {
        // Empty optional number fields are ignored, so a play can save with just one number.
        numbers
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

// MARK: - Play Edit State

struct PlayEditState: Identifiable {
    // MARK: Properties

    let id: String
    var title: String
    var numberOne: String
    var numberTwo: String
    var numberThree: String
    var categoryID: String
    let categories: [PlayCategory]

    // MARK: Initialization

    init(play: PlayCallItem, categoryID: String, categories: [PlayCategory]) {
        id = play.id
        title = play.title
        numberOne = play.numbers[safe: 0] ?? ""
        numberTwo = play.numbers[safe: 1] ?? ""
        numberThree = play.numbers[safe: 2] ?? ""
        self.categoryID = categoryID
        self.categories = categories
    }
}

// MARK: - Safe Collection Access

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
