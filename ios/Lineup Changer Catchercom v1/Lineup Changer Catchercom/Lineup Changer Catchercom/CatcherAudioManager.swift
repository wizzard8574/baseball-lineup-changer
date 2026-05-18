import AVFoundation
import Combine
import Foundation

@MainActor
final class CatcherAudioManager: NSObject, ObservableObject {
    @Published private(set) var audioState = "Audio ready."
    @Published private(set) var lastMessage = "No call sent yet."
    @Published private(set) var history: [CallHistoryItem] = CallHistoryItem.loadSavedHistory()

    private let speechSynthesizer = AVSpeechSynthesizer()
    private let voiceEngine = AVAudioEngine()
    private var isTransmittingVoice = false

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
        guard !isTransmittingVoice else { return }

        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            beginVoiceTransmit()
        case .denied:
            audioState = "Microphone access is off."
            lastMessage = "Enable microphone access in Settings."
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] isGranted in
                Task { @MainActor in
                    guard let self else { return }

                    if isGranted {
                        self.beginVoiceTransmit()
                    } else {
                        self.audioState = "Microphone access is off."
                        self.lastMessage = "Enable microphone access in Settings."
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

    func sendCommonMessage(title: String, payload: String, location: CatcherLocation) {
        let messageTitle = "\(title) \(location.title)"
        speak(messageTitle)
        markSent(messageTitle)
    }

    func sendPlay(title: String, number: String) {
        speak(number)
        markSent("\(title): \(number)")
    }

    func clearHistory() {
        history = []
        CallHistoryItem.saveHistory(history)
    }

    private func speak(_ text: String) {
        stopVoiceTransmit()

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
        history.insert(CallHistoryItem(title: title, sentAt: Date()), at: 0)
        CallHistoryItem.saveHistory(history)
    }

    private func beginVoiceTransmit() {
        do {
            if speechSynthesizer.isSpeaking {
                speechSynthesizer.stopSpeaking(at: .immediate)
            }

            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [.allowBluetoothHFP, .allowBluetoothA2DP, .defaultToSpeaker, .duckOthers]
            )
            try audioSession.setActive(true)

            if voiceEngine.isRunning {
                voiceEngine.stop()
            }

            let inputNode = voiceEngine.inputNode
            let inputFormat = inputNode.outputFormat(forBus: 0)
            voiceEngine.disconnectNodeOutput(inputNode)
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
}

struct CallHistoryItem: Identifiable, Equatable, Codable {
    let id: String
    let title: String
    let sentAt: Date

    private static let storageKey = "catchercom.callHistory"

    init(id: String = UUID().uuidString, title: String, sentAt: Date) {
        self.id = id
        self.title = title
        self.sentAt = sentAt
    }

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
