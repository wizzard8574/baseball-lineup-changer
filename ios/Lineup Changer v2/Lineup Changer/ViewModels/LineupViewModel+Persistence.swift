// Created by Rich Morris on 5/5/26.
// Lineup Changer
// LineupViewModel+Persistence.swift
//
//
//
// Persistence-related LineupViewModel functionality.
// This extension saves and restores full app state from UserDefaults.
import Foundation

// MARK: - App State Persistence
extension LineupViewModel {
    // MARK: - Save / Load
    // Encodes the current app state and stores it in UserDefaults.
    func save() {
        // Avoid recursive saves while a saved state is actively being restored.
        guard !isApplyingSavedState else { return }

        do {
            // Build a complete AppState snapshot before encoding it.
            let data = try JSONEncoder().encode(currentAppState())
            userDefaults.set(data, forKey: saveKey)
        } catch {
            // Log save failures instead of interrupting the user's workflow.
            print("Failed to save app state: \(error)")
        }
    }

    // Loads saved app state from UserDefaults and applies it to the view model.
    func load() {
        // If no saved data exists, the app starts from default in-memory values.
        guard let data = userDefaults.data(forKey: saveKey) else { return }

        do {
            // Suppress automatic saves while restoring published properties.
            isApplyingSavedState = true
            defer { isApplyingSavedState = false }

            // Decode the saved JSON into the app's persisted state model.
            let state = try JSONDecoder().decode(AppState.self, from: data)
            applyAppState(state)
        } catch {
            // Reset the guard flag manually because decoding failed before normal completion.
            isApplyingSavedState = false
            print("Failed to load app state: \(error)")
            // Preserve the unreadable payload for possible manual recovery/debugging.
            userDefaults.set(data, forKey: "LineupChangerRecoveryBackup")
        }
    }
}
