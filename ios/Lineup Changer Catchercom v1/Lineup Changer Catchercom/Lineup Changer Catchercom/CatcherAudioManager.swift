import AVFoundation
import Combine
import Foundation

@MainActor
final class CatcherAudioManager: NSObject, ObservableObject {
    @Published private(set) var audioState = "Audio ready."
    @Published private(set) var lastMessage = "No call sent yet."

    private let speechSynthesizer = AVSpeechSynthesizer()

    var canSendSignal: Bool {
        true
    }

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

    func startVoiceTransmit() {
        lastMessage = "Voice transmit started"
    }

    func stopVoiceTransmit() {
        lastMessage = "Voice transmit stopped"
    }

    func sendCommonMessage(title: String, payload: String, location: CatcherLocation) {
        let messageTitle = "\(title) \(location.title)"
        speak(messageTitle)
        markSent(messageTitle)
    }

    private func speak(_ text: String) {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try audioSession.setActive(true)
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
        lastMessage = "Spoke \(title)"
    }
}

enum CatcherPitch: String, CaseIterable, Identifiable {
    case fastball
    case curveball
    case change
    case splitter
    case cutter

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fastball:
            return "Fastball"
        case .curveball:
            return "Curveball"
        case .change:
            return "Change"
        case .splitter:
            return "Splitter"
        case .cutter:
            return "Cutter"
        }
    }
}

enum CatcherLocation: String, CaseIterable, Identifiable {
    case up
    case down
    case out
    case `in`
    case middle

    var id: String { rawValue }

    var title: String {
        switch self {
        case .up:
            return "Up"
        case .down:
            return "Down"
        case .out:
            return "Out"
        case .in:
            return "In"
        case .middle:
            return "Middle"
        }
    }
}

struct CatcherSignal {
    let pitch: CatcherPitch
    let location: CatcherLocation

    var title: String {
        "\(pitch.title) \(location.title)"
    }
}

enum CatcherNumberSign: String, CaseIterable, Identifiable {
    case one = "1"
    case two = "2"
    case twentyTwo = "22"
    case three = "3"
    case thirtyThree = "33"

    var id: String { rawValue }
    var title: String { rawValue }
}
