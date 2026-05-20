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
