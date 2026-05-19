import SwiftUI

struct CallsView: View {
    // MARK: - Dependencies

    @ObservedObject var audio: CatcherAudioManager

    // MARK: - State

    // The pitch list is user-editable and persisted in the same order the user drags it into.
    @State private var pitchOrder: [PitchCallItem] = PitchCallItem.loadSavedOrder()
    @State private var newPitchTitle = ""
    @State private var lastSpokenPitchID: String?
    @State private var editingPitch: PitchEditState?
    @FocusState private var isNewPitchTitleFocused: Bool

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                Section(header: ListSectionHeader(title: "Audio")) {
                    AudioVoiceCard(
                        statusTitle: statusTitle,
                        statusIcon: statusIcon,
                        audioState: audio.audioState,
                        outputDeviceName: audio.outputDeviceName,
                        canTransmit: true,
                        startTransmit: audio.startVoiceTransmit,
                        stopTransmit: audio.stopVoiceTransmit
                    )
                }
                .catcherListRowBackground()

                Section(header: ListSectionHeader(title: "Calls")) {
                    addPitchRow

                    ForEach(pitchOrder) { pitch in
                        VStack(alignment: .leading, spacing: 6) {
                            PitchSignRow(item: pitch, audio: audio) {
                                lastSpokenPitchID = pitch.id
                            }

                            if lastSpokenPitchID == pitch.id {
                                SpokenMessageText(message: audio.lastMessage)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Delete", role: .destructive) {
                                deletePitch(pitch)
                            }

                            Button("Edit") {
                                editingPitch = PitchEditState(item: pitch)
                            }
                            .tint(.blue)
                        }
                    }
                    .onMove(perform: movePitch)
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
            .sheet(item: $editingPitch) { editState in
                PitchEditView(editState: editState) { updatedPitch in
                    updatePitch(updatedPitch)
                    editingPitch = nil
                } onCancel: {
                    editingPitch = nil
                }
            }
            .appScreenBackground()
        }
    }

    // MARK: - Add Row

    private var addPitchRow: some View {
        HStack {
            TextField("New pitch", text: $newPitchTitle)
                .textInputAutocapitalization(.words)
                .textFieldStyle(.roundedBorder)
                .focused($isNewPitchTitleFocused)
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

    // MARK: - Actions

    private func addPitch() {
        let trimmedTitle = newPitchTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        // Dismiss the keyboard immediately after Add, matching the phone behavior requested for game use.
        isNewPitchTitleFocused = false
        pitchOrder.append(.custom(trimmedTitle))
        newPitchTitle = ""
    }

    private func deletePitch(_ pitch: PitchCallItem) {
        pitchOrder.removeAll { $0.id == pitch.id }
    }

    private func updatePitch(_ pitch: PitchCallItem) {
        guard let index = pitchOrder.firstIndex(where: { $0.id == pitch.id }) else { return }
        pitchOrder[index] = pitch
    }

    private func movePitch(from source: IndexSet, to destination: Int) {
        withAnimation(.snappy) {
            pitchOrder.move(fromOffsets: source, toOffset: destination)
        }
    }
}

// MARK: - Pitch Model

private struct PitchCallItem: Identifiable, Equatable, Codable {
    let id: String
    let title: String
    let payloadValue: String

    // UserDefaults keeps this lightweight app persistent without introducing a database.
    private static let storageKey = "catchercom.pitchOrder"

    // MARK: Defaults

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
        pitchCallItem(id: UUID().uuidString, title: title)
    }

    static func edited(id: String, title: String) -> PitchCallItem {
        pitchCallItem(id: id, title: title)
    }

    // MARK: Persistence

    private static func pitchCallItem(id: String, title: String) -> PitchCallItem {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        // Payload is normalized in case a future receiver needs a machine-friendly value.
        let payload = trimmedTitle
            .uppercased()
            .replacingOccurrences(of: " ", with: "_")

        return PitchCallItem(id: id, title: trimmedTitle, payloadValue: payload)
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

// MARK: - Pitch Editing

private struct PitchEditState: Identifiable {
    let id: String
    var title: String

    init(item: PitchCallItem) {
        id = item.id
        title = item.title
    }
}

private struct PitchEditView: View {
    // MARK: State

    @State private var editState: PitchEditState
    let onSave: (PitchCallItem) -> Void
    let onCancel: () -> Void

    // MARK: Initialization

    init(
        editState: PitchEditState,
        onSave: @escaping (PitchCallItem) -> Void,
        onCancel: @escaping () -> Void
    ) {
        _editState = State(initialValue: editState)
        self.onSave = onSave
        self.onCancel = onCancel
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            Form {
                Section("Call") {
                    TextField("Pitch name", text: $editState.title)
                        .textInputAutocapitalization(.words)
                }
            }
            .navigationTitle("Edit Call")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(.edited(id: editState.id, title: editState.title))
                    }
                    .disabled(editState.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Pitch Row

private struct PitchSignRow: View {
    // MARK: Properties

    let item: PitchCallItem
    @ObservedObject var audio: CatcherAudioManager
    let onSend: () -> Void

    // MARK: Body

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

    // MARK: Controls

    private func locationButton(_ location: CatcherLocation, width: CGFloat = 52) -> some View {
        Button {
            onSend()
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
