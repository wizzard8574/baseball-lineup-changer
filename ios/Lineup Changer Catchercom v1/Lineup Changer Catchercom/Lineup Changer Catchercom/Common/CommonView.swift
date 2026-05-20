import SwiftUI

struct CommonView: View {
    // MARK: - Dependencies

    @ObservedObject var audio: CatcherAudioManager

    // MARK: - State

    // Common calls are custom user messages with one saved location each.
    @State private var commonItems: [CommonMessageItem] = CommonMessageItem.loadSavedOrder()
    @State private var newCommonTitle = ""
    @State private var newCommonLocation: CatcherLocation = .middle
    @State private var lastSpokenCommonItemID: String?
    @State private var editingCommonItem: CommonMessageEditState?
    @FocusState private var isNewCommonTitleFocused: Bool

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

                Section(header: ListSectionHeader(title: "Common")) {
                    addCommonRow

                    if commonItems.isEmpty {
                        Text("No common messages yet")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(commonItems) { item in
                            VStack(alignment: .leading, spacing: 6) {
                                CommonMessageRow(
                                    item: item,
                                    onSend: {
                                        lastSpokenCommonItemID = item.id
                                        audio.sendCommonMessage(
                                            title: item.title,
                                            payload: item.payloadValue,
                                            location: item.location
                                        )
                                    }
                                )

                                if lastSpokenCommonItemID == item.id {
                                    SpokenMessageText(message: audio.lastMessage)
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("Delete", role: .destructive) {
                                    deleteCommonItem(item)
                                }

                                Button("Edit") {
                                    editingCommonItem = CommonMessageEditState(item: item)
                                }
                                .tint(.blue)
                            }
                        }
                        .onMove(perform: moveCommonItems)
                    }
                }
                .catcherListRowBackground()
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .navigationTitle("Common")
            .toolbar {
                EditButton()
            }
            .onChange(of: commonItems) { _, newValue in
                CommonMessageItem.saveOrder(newValue)
            }
            .sheet(item: $editingCommonItem) { editState in
                CommonMessageEditView(editState: editState) { updatedItem in
                    updateCommonItem(updatedItem)
                    editingCommonItem = nil
                } onCancel: {
                    editingCommonItem = nil
                }
            }
            .appScreenBackground()
        }
    }

    // MARK: - Add Row

    private var addCommonRow: some View {
        HStack {
            TextField("New common call", text: $newCommonTitle)
                .textInputAutocapitalization(.words)
                .textFieldStyle(.roundedBorder)
                .focused($isNewCommonTitleFocused)
                .submitLabel(.done)
                .onSubmit(addCommonItem)

            Picker("Location", selection: $newCommonLocation) {
                ForEach(CatcherLocation.allCases) { location in
                    Text(location.title).tag(location)
                }
            }
            .pickerStyle(.menu)

            Button("Add") {
                addCommonItem()
            }
            .buttonStyle(.borderedProminent)
            .disabled(newCommonTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private var statusTitle: String { "Audio Ready" }
    private var statusIcon: String { "speaker.wave.2.fill" }

    // MARK: - Actions

    private func addCommonItem() {
        let trimmedTitle = newCommonTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        // Dismiss the keyboard after adding so the list is usable immediately on a phone.
        isNewCommonTitleFocused = false
        commonItems.append(.custom(title: trimmedTitle, location: newCommonLocation))
        newCommonTitle = ""
        newCommonLocation = .middle
    }

    private func deleteCommonItem(_ item: CommonMessageItem) {
        commonItems.removeAll { $0.id == item.id }
    }

    private func updateCommonItem(_ item: CommonMessageItem) {
        guard let index = commonItems.firstIndex(where: { $0.id == item.id }) else { return }
        commonItems[index] = item
    }

    private func moveCommonItems(from source: IndexSet, to destination: Int) {
        withAnimation(.snappy) {
            commonItems.move(fromOffsets: source, toOffset: destination)
        }
    }
}
