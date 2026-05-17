import SwiftUI

struct CommonView: View {
    @ObservedObject var audio: CatcherAudioManager
    @State private var commonItems: [CommonMessageItem] = CommonMessageItem.loadSavedOrder()
    @State private var newCommonTitle = ""
    @State private var newCommonLocation: CatcherLocation = .middle
    @FocusState private var isNewCommonTitleFocused: Bool

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

                Section(header: ListSectionHeader(title: "Common")) {
                    addCommonRow

                    if commonItems.isEmpty {
                        Text("No common messages yet")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(commonItems) { item in
                            CommonMessageRow(
                                item: item,
                                onSend: {
                                    audio.sendCommonMessage(
                                        title: item.title,
                                        payload: item.payloadValue,
                                        location: item.location
                                    )
                                }
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("Delete", role: .destructive) {
                                    deleteCommonItem(item)
                                }
                            }
                        }
                    }

                    Text(audio.lastMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .catcherListRowBackground()
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .navigationTitle("Common")
            .onChange(of: commonItems) { _, newValue in
                CommonMessageItem.saveOrder(newValue)
            }
            .appScreenBackground()
        }
    }

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

    private func addCommonItem() {
        let trimmedTitle = newCommonTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        commonItems.append(.custom(title: trimmedTitle, location: newCommonLocation))
        newCommonTitle = ""
        newCommonLocation = .middle
        isNewCommonTitleFocused = false
    }

    private func deleteCommonItem(_ item: CommonMessageItem) {
        commonItems.removeAll { $0.id == item.id }
    }
}

private struct CommonMessageItem: Identifiable, Equatable, Codable {
    let id: String
    let title: String
    let payloadValue: String
    let locationRawValue: String

    var location: CatcherLocation {
        CatcherLocation(rawValue: locationRawValue) ?? .middle
    }

    private static let storageKey = "catchercom.commonMessages"

    static func custom(title: String, location: CatcherLocation) -> CommonMessageItem {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let payload = trimmedTitle
            .uppercased()
            .replacingOccurrences(of: " ", with: "_")

        return CommonMessageItem(
            id: UUID().uuidString,
            title: trimmedTitle,
            payloadValue: payload,
            locationRawValue: location.rawValue
        )
    }

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

private struct CommonMessageRow: View {
    let item: CommonMessageItem
    let onSend: () -> Void

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
