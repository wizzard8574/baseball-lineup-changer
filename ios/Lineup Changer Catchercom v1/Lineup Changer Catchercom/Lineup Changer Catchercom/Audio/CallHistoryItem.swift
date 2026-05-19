//
//  CallHistoryItem.swift
//  Lineup Changer Catchercom
//
//  Created by Rich Morris on 5/18/26.
//

import SwiftUI

struct CallHistoryItem: Identifiable, Equatable, Codable {
    // MARK: - Properties

    let id: String
    let title: String
    let sentAt: Date

    // Stored locally so call history survives closing the app.
    private static let storageKey = "catchercom.callHistory"

    // MARK: - Initialization

    init(id: String = UUID().uuidString, title: String, sentAt: Date) {
        self.id = id
        self.title = title
        self.sentAt = sentAt
    }

    // MARK: - Persistence

    static func loadSavedHistory() -> [CallHistoryItem] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let savedHistory = try? JSONDecoder().decode([CallHistoryItem].self, from: data) else {
            return []
        }

        return savedHistory
    }

    static func saveHistory(_ history: [CallHistoryItem]) {
        guard let data = try? JSONEncoder().encode(history) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
