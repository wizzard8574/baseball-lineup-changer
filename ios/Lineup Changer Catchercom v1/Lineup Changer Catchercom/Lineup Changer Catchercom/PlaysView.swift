import SwiftUI

struct PlaysView: View {
    @ObservedObject var audio: CatcherAudioManager

    var body: some View {
        NavigationStack {
            List {
                Section(header: ListSectionHeader(title: "Audio")) {
                    AudioVoiceCard(
                        statusTitle: statusTitle,
                        statusIcon: statusIcon,
                        audioState: audio.audioState,
                        canTransmit: true,
                        startTransmit: audio.startVoiceTransmit,
                        stopTransmit: audio.stopVoiceTransmit
                    )
                }
                .catcherListRowBackground()

                Section(header: ListSectionHeader(title: "Plays")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("No Plays Yet")
                            .font(.headline)

                        Text("Add play controls here when you are ready.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .catcherListRowBackground()
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .navigationTitle("Plays")
            .appScreenBackground()
        }
    }

    private var statusTitle: String {
        "Audio Ready"
    }

    private var statusIcon: String {
        "speaker.wave.2.fill"
    }
}
