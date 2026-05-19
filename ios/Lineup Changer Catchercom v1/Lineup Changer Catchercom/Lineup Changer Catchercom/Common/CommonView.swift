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

// MARK: - Common Model

private struct CommonMessageItem: Identifiable, Equatable, Codable {
    let id: String
    let title: String
    let payloadValue: String
    let locationRawValue: String

    // Store the raw value, then recover safely if a saved value ever becomes invalid.
    var location: CatcherLocation {
        CatcherLocation(rawValue: locationRawValue) ?? .middle
    }

    private static let storageKey = "catchercom.commonMessages"

    // MARK: Factories

    static func custom(title: String, location: CatcherLocation) -> CommonMessageItem {
        commonMessageItem(id: UUID().uuidString, title: title, location: location)
    }

    static func edited(id: String, title: String, location: CatcherLocation) -> CommonMessageItem {
        commonMessageItem(id: id, title: title, location: location)
    }

    private static func commonMessageItem(id: String, title: String, location: CatcherLocation) -> CommonMessageItem {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        // Payload is normalized in case a future receiver needs a machine-friendly value.
        let payload = trimmedTitle
            .uppercased()
            .replacingOccurrences(of: " ", with: "_")

        return CommonMessageItem(
            id: id,
            title: trimmedTitle,
            payloadValue: payload,
            locationRawValue: location.rawValue
        )
    }

    // MARK: Persistence

    static func loadSavedOrder() -> [CommonMessageItem] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let savedOrder = try? JSONDecoder().decode([CommonMessageItem].self, from: data) else {
            return []
        }

        return savedOrder
    }

    static func saveOrder(_ order: [CommonMessageItem]) {
        guard let data = try? JSONEncoder().encode(order) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

// MARK: - Common Editing

private struct CommonMessageEditState: Identifiable {
    let id: String
    var title: String
    var location: CatcherLocation

    init(item: CommonMessageItem) {
        id = item.id
        title = item.title
        location = item.location
    }
}

private struct CommonMessageEditView: View {
    // MARK: State

    @State private var editState: CommonMessageEditState
    let onSave: (CommonMessageItem) -> Void
    let onCancel: () -> Void

    // MARK: Initialization

    init(
        editState: CommonMessageEditState,
        onSave: @escaping (CommonMessageItem) -> Void,
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
                Section("Common Call") {
                    TextField("Name", text: $editState.title)
                        .textInputAutocapitalization(.words)

                    Picker("Location", selection: $editState.location) {
                        ForEach(CatcherLocation.allCases) { location in
                            Text(location.title).tag(location)
                        }
                    }
                }
            }
            .navigationTitle("Edit Common")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(
                            .edited(
                                id: editState.id,
                                title: editState.title,
                                location: editState.location
                            )
                        )
                    }
                    .disabled(editState.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Common Row

private struct CommonMessageRow: View {
    // MARK: Properties

    let item: CommonMessageItem
    let onSend: () -> Void

    // MARK: Body

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)

                Text(item.location.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Send") {
                onSend()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
