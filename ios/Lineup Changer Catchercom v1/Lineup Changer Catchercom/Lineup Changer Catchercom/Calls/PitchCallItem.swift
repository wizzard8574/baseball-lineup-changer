import Foundation

// MARK: - Pitch Model

struct PitchCallItem: Identifiable, Equatable, Codable {
    let id: String
    let title: String
    let payloadValue: String

    // UserDefaults keeps this lightweight app persistent without introducing a database.
    private static let storageKey = "catchercom.pitchOrder"

    // MARK: Defaults

    static var defaultOrder: [PitchCallItem] {
        [
            .builtIn(.fastball),
            .builtIn(.splitter),
            .builtIn(.curveball),
            .builtIn(.cutter),
            .builtIn(.change)
        ]
    }

    static func builtIn(_ pitch: CatcherPitch) -> PitchCallItem {
        PitchCallItem(id: pitch.rawValue, title: pitch.title, payloadValue: pitch.rawValue)
    }

    static func custom(_ title: String) -> PitchCallItem {
        pitchCallItem(id: UUID().uuidString, title: title)
    }

    static func edited(id: String, title: String) -> PitchCallItem {
        pitchCallItem(id: id, title: title)
    }

    // MARK: Persistence

    private static func pitchCallItem(id: String, title: String) -> PitchCallItem {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        // Payload is normalized in case a future receiver needs a machine-friendly value.
        let payload = trimmedTitle
            .uppercased()
            .replacingOccurrences(of: " ", with: "_")

        return PitchCallItem(id: id, title: trimmedTitle, payloadValue: payload)
    }

    static func loadSavedOrder() -> [PitchCallItem] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let savedOrder = try? JSONDecoder().decode([PitchCallItem].self, from: data) else {
            return defaultOrder
        }

        return savedOrder
    }

    static func saveOrder(_ order: [PitchCallItem]) {
        guard let data = try? JSONEncoder().encode(order) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
