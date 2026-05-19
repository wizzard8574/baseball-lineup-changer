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
    @Published private(set) var audioState = "Audio ready."
    @Published private(set) var lastMessage = "No call sent yet."
    @Published private(set) var history: [CallHistoryItem] = CallHistoryItem.loadSavedHistory()
    @Published private(set) var outputDeviceName = "iPhone Speaker"

    // MARK: - Audio Engines

    private let speechSynthesizer = AVSpeechSynthesizer()
    private let voiceEngine = AVAudioEngine()
    private var isTransmittingVoice = false

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

    // MARK: - Signal Playback

    func sendSignal(pitch: CatcherPitch, location: CatcherLocation) {
        let signal = CatcherSignal(pitch: pitch, location: location)
        speak(signal.title)
        markSent(signal.title)
    }

    func sendSignal(sign: CatcherNumberSign) {
        speak(sign.title)
        markSent(sign.title)
    }

    func sendSignal(sign: CatcherNumberSign, location: CatcherLocation) {
        let title = "\(sign.title) \(location.title)"
        speak(title)
        markSent(title)
    }

    func sendSignal(signTitle: String, signPayload: String, location: CatcherLocation) {
        let title = "\(signTitle) \(location.title)"
        speak(title)
        markSent(title)
    }

    func sendSignal(pitchTitle: String, pitchPayload: String, location: CatcherLocation) {
        let title = "\(pitchTitle) \(location.title)"
        speak(title)
        markSent(title)
    }

    // MARK: - Voice Transmit

    func startVoiceTransmit() {
        guard !isTransmittingVoice else { return }

        // iOS requires explicit microphone permission before we can route live voice through the audio engine.
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            beginVoiceTransmit()
        case .denied:
            audioState = "Microphone access is off."
            lastMessage = "Enable microphone access in Settings."
        case .undetermined:
            AVAudioApplication.requestRecordPermission { [weak self] isGranted in
                guard let audioManager = self else { return }

                Task { @MainActor in
                    if isGranted {
                        audioManager.beginVoiceTransmit()
                    } else {
                        audioManager.audioState = "Microphone access is off."
                        audioManager.lastMessage = "Enable microphone access in Settings."
                    }
                }
            }
        @unknown default:
            audioState = "Microphone access is unavailable."
            lastMessage = "Could not start voice transmit."
        }
    }

    func stopVoiceTransmit() {
        guard isTransmittingVoice else { return }

        voiceEngine.stop()
        voiceEngine.disconnectNodeOutput(voiceEngine.inputNode)
        isTransmittingVoice = false
        audioState = "Audio ready."
        lastMessage = "Voice transmit stopped"
    }

    // MARK: - Common and Plays

    func sendCommonMessage(title: String, payload: String, location: CatcherLocation) {
        let messageTitle = "\(title) \(location.title)"
        speak(messageTitle)
        markSent(messageTitle)
    }

    func sendPlay(title: String, number: String) {
        speak(number)
        markSent("\(title): \(number)")
    }

    // MARK: - History

    func clearHistory() {
        history = []
        CallHistoryItem.saveHistory(history)
    }

    // MARK: - Speech

    private func speak(_ text: String) {
        // Sending a spoken call should always stop live mic mode first so speech and mic audio do not fight.
        stopVoiceTransmit()

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try audioSession.setActive(true)
            updateOutputDeviceName()
            audioState = "Audio ready."
        } catch {
            audioState = "Could not start audio."
            lastMessage = error.localizedDescription
            return
        }

        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.volume = 1.0
        utterance.pitchMultiplier = 1.0
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

        speechSynthesizer.speak(utterance)
    }

    private func markSent(_ title: String) {
        // Newest calls stay at the top of History, then persist immediately so nothing is lost on app close.
        lastMessage = "Spoke \(title)"
        history.insert(CallHistoryItem(title: title, sentAt: Date()), at: 0)
        CallHistoryItem.saveHistory(history)
    }

    // MARK: - Microphone Routing

    private func beginVoiceTransmit() {
        do {
            if speechSynthesizer.isSpeaking {
                speechSynthesizer.stopSpeaking(at: .immediate)
            }

            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.allowBluetoothA2DP, .duckOthers]
            )
            try audioSession.setActive(true)
            try preferBuiltInMicrophone(audioSession)
            updateOutputDeviceName()

            if voiceEngine.isRunning {
                voiceEngine.stop()
            }

            let inputNode = voiceEngine.inputNode
            let inputFormat = inputNode.outputFormat(forBus: 0)
            voiceEngine.disconnectNodeOutput(inputNode)
            // This creates the push-to-talk path: phone microphone into the active audio output route.
            voiceEngine.connect(inputNode, to: voiceEngine.mainMixerNode, format: inputFormat)

            voiceEngine.prepare()
            try voiceEngine.start()

            isTransmittingVoice = true
            audioState = "Live mic is on."
            lastMessage = "Hold to talk"
        } catch {
            voiceEngine.stop()
            isTransmittingVoice = false
            audioState = "Could not start live mic."
            lastMessage = error.localizedDescription
        }
    }

    private func preferBuiltInMicrophone(_ audioSession: AVAudioSession) throws {
        guard let availableInputs = audioSession.availableInputs else { return }

        // Use the phone as the coach's microphone even when audio output is going to a connected device.
        if let builtInMicrophone = availableInputs.first(where: { $0.portType == .builtInMic }) {
            try audioSession.setPreferredInput(builtInMicrophone)
        }
    }

    // MARK: - Output Route

    @objc private func audioRouteDidChange() {
        Task { @MainActor in
            updateOutputDeviceName()
        }
    }

    private func updateOutputDeviceName() {
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs

        guard let output = outputs.first else {
            outputDeviceName = "No output device"
            return
        }

        outputDeviceName = output.portName
    }
}

// MARK: - Signal Model

struct CatcherSignal {
    let pitch: CatcherPitch
    let location: CatcherLocation

    var title: String {
        "\(pitch.title) \(location.title)"
    }
}
