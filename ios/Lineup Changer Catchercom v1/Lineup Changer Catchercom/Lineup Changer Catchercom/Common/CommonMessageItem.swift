import Foundation

// MARK: - Common Model

struct CommonMessageItem: Identifiable, Equatable, Codable {
    let id: String
    let title: String
    let payloadValue: String
    let locationRawValue: String

    // Store the raw value, then recover safely if a saved value ever becomes invalid.
    var location: CatcherLocation {
        CatcherLocation(rawValue: locationRawValue) ?? .middle
    }

    private static let storageKey = "catchercom.commonMessages"

    // MARK: Factories

    static func custom(title: String, location: CatcherLocation) -> CommonMessageItem {
        commonMessageItem(id: UUID().uuidString, title: title, location: location)
    }

    static func edited(id: String, title: String, location: CatcherLocation) -> CommonMessageItem {
        commonMessageItem(id: id, title: title, location: location)
    }

    private static func commonMessageItem(id: String, title: String, location: CatcherLocation) -> CommonMessageItem {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        // Payload is normalized in case a future receiver needs a machine-friendly value.
        let payload = trimmedTitle
            .uppercased()
            .replacingOccurrences(of: " ", with: "_")

        return CommonMessageItem(
            id: id,
            title: trimmedTitle,
            payloadValue: payload,
            locationRawValue: location.rawValue
        )
    }

    // MARK: Persistence

    static func loadSavedOrder() -> [CommonMessageItem] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let savedOrder = try? JSONDecoder().decode([CommonMessageItem].self, from: data) else {
            return []
        }

        return savedOrder
    }

    static func saveOrder(_ order: [CommonMessageItem]) {
        guard let data = try? JSONEncoder().encode(order) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
