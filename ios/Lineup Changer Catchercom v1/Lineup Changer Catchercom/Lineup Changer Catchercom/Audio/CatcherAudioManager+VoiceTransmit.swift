//

import AVFoundation
import Foundation

extension CatcherAudioManager {
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

    // MARK: - Microphone Routing

    func beginVoiceTransmit() {
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

    func preferBuiltInMicrophone(_ audioSession: AVAudioSession) throws {
        guard let availableInputs = audioSession.availableInputs else { return }

        // Use the phone as the coach's microphone even when audio output is going to a connected device.
        if let builtInMicrophone = availableInputs.first(where: { $0.portType == .builtInMic }) {
            try audioSession.setPreferredInput(builtInMicrophone)
        }
    }
}
//  CatcherAudioManager+VoiceTransmit.swift
//  Lineup Changer Catchercom
//
//  Created by Rich Morris on 5/19/26.
//
