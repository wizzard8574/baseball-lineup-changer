import SwiftUI

struct CallsView: View {
    @ObservedObject var audio: CatcherAudioManager
    @State private var pitchOrder: [PitchCallItem] = PitchCallItem.loadSavedOrder()
    @State private var newPitchTitle = ""

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

                Section(header: ListSectionHeader(title: "Calls")) {
                    addPitchRow

                    ForEach(pitchOrder) { pitch in
                        PitchSignRow(item: pitch, audio: audio)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("Delete", role: .destructive) {
                                    deletePitch(pitch)
                                }
                            }
                    }
                    .onMove(perform: movePitch)

                    Text(audio.lastMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .catcherListRowBackground()
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .navigationTitle("Calls")
            .toolbar {
                EditButton()
            }
            .onChange(of: pitchOrder) { _, newValue in
                PitchCallItem.saveOrder(newValue)
            }
            .appScreenBackground()
        }
    }

    private var addPitchRow: some View {
        HStack {
            TextField("New pitch", text: $newPitchTitle)
                .textInputAutocapitalization(.words)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.done)
                .onSubmit(addPitch)

            Button("Add") {
                addPitch()
            }
            .buttonStyle(.borderedProminent)
            .disabled(newPitchTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private var statusTitle: String { "Audio Ready" }
    private var statusIcon: String { "speaker.wave.2.fill" }

    private func addPitch() {
        let trimmedTitle = newPitchTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        pitchOrder.append(.custom(trimmedTitle))
        newPitchTitle = ""
    }

    private func deletePitch(_ pitch: PitchCallItem) {
        pitchOrder.removeAll { $0.id == pitch.id }
    }

    private func movePitch(from source: IndexSet, to destination: Int) {
        withAnimation(.snappy) {
            pitchOrder.move(fromOffsets: source, toOffset: destination)
        }
    }
}

private struct PitchCallItem: Identifiable, Equatable, Codable {
    let id: String
    let title: String
    let payloadValue: String

    private static let storageKey = "catchercom.pitchOrder"

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
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let payload = trimmedTitle
            .uppercased()
            .replacingOccurrences(of: " ", with: "_")

        return PitchCallItem(id: UUID().uuidString, title: trimmedTitle, payloadValue: payload)
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

private struct PitchSignRow: View {
    let item: PitchCallItem
    @ObservedObject var audio: CatcherAudioManager

    var body: some View {
        HStack(spacing: 12) {
            Text(item.title)
                .font(.headline)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(width: 86, alignment: .leading)

            VStack(spacing: 6) {
                locationButton(.up)

                HStack(spacing: 8) {
                    locationButton(.out)
                    locationButton(.middle, width: 58)
                    locationButton(.in)
                }

                locationButton(.down)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func locationButton(_ location: CatcherLocation, width: CGFloat = 52) -> some View {
        Button {
            audio.sendSignal(pitchTitle: item.title, pitchPayload: item.payloadValue, location: location)
        } label: {
            Text(location.title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: width, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.blue)
                )
        }
        .buttonStyle(.plain)
        .opacity(audio.canSendSignal ? 1 : 0.85)
    }
}
