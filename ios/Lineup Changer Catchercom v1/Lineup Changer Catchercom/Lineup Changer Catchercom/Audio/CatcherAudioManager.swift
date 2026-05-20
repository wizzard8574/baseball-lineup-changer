//
//  CatcherAudioManager.swift
//  Lineup Changer Catchercom
//
//  Created by Rich Morris on 5/18/26.
//

import AVFoundation
import Combine
import Foundation

@MainActor
final class CatcherAudioManager: NSObject, ObservableObject {
    // MARK: - Published State

    // Published values drive the audio card, the "what was spoken" labels, and the History tab.
    @Published var audioState = "Audio ready."
    @Published var lastMessage = "No call sent yet."
    @Published var history: [CallHistoryItem] = CallHistoryItem.loadSavedHistory()
    @Published var outputDeviceName = "iPhone Speaker"

    // MARK: - Audio Engines

    let speechSynthesizer = AVSpeechSynthesizer()
    let voiceEngine = AVAudioEngine()
    var isTransmittingVoice = false
    let spokenWordPause: TimeInterval = 0.02

    // MARK: - Initialization

    override init() {
        super.init()
        updateOutputDeviceName()

        // Keep the displayed output device current when the user connects or disconnects headphones.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioRouteDidChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Capabilities

    var canSendSignal: Bool {
        true
    }

    // MARK: - History

    func clearHistory() {
        history = []
        CallHistoryItem.saveHistory(history)
    }
}

