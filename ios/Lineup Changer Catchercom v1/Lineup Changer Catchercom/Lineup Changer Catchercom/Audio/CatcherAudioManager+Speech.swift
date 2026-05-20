//
//  CatcherAudioManager+Speech.swift
//  Lineup Changer Catchercom
//
//  Created by Rich Morris on 5/19/26.
//

import AVFoundation
import Foundation

// MARK: - Signal Playback

extension CatcherAudioManager {
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

    // MARK: - Speech

    func speak(_ text: String) {
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

        let utterances = makeUtterances(for: text)

        utterances.forEach { speechSynthesizer.speak($0) }
    }

    func markSent(_ title: String) {
        // Newest calls stay at the top of History, then persist immediately so nothing is lost on app close.
        lastMessage = "Spoke \(title)"
        history.insert(CallHistoryItem(title: title, sentAt: Date()), at: 0)
        CallHistoryItem.saveHistory(history)
    }

    func makeUtterances(for text: String) -> [AVSpeechUtterance] {
        let words = text.split(separator: " ", maxSplits: 1).map(String.init)
        guard words.count == 2 else {
            return [makeUtterance(text)]
        }

        let firstWord = makeUtterance(words[0])
        let remainingWords = makeUtterance(words[1])
        // Pause after the first spoken word so the call is easier to catch under game noise.
        remainingWords.preUtteranceDelay = spokenWordPause

        return [firstWord, remainingWords]
    }

    func makeUtterance(_ text: String) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.volume = 1.0
        utterance.pitchMultiplier = 1.0
        utterance.voice = preferredSpeechVoice()
        return utterance
    }

    func preferredSpeechVoice() -> AVSpeechSynthesisVoice? {
        let englishVoices = AVSpeechSynthesisVoice.speechVoices().filter {
            $0.language == "en-US" || $0.language == "en-GB"
        }

        // Siri's exact assistant voice is private, but some Siri-like system voices may be exposed here.
        return englishVoices.first {
            $0.name.localizedCaseInsensitiveContains("Siri") && $0.quality == .premium
        } ?? englishVoices.first {
            $0.name.localizedCaseInsensitiveContains("Siri") && $0.quality == .enhanced
        } ?? englishVoices.first {
            $0.quality == .premium
        } ?? englishVoices.first {
            $0.quality == .enhanced
        } ?? AVSpeechSynthesisVoice(language: "en-US")
    }
}
