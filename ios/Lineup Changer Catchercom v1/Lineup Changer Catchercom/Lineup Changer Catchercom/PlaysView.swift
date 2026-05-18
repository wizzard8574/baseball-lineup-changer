import SwiftUI

struct PlaysView: View {
    @ObservedObject var audio: CatcherAudioManager
    @State private var categories: [PlayCategory] = PlayCategory.loadSavedCategories()
    @State private var selectedCategoryID = PlayCategory.loadSavedCategories().first?.id ?? PlayCategory.defaultCategoryID
    @State private var newCategoryTitle = ""
    @State private var newPlayTitle = ""
    @State private var newPlayNumberOne = ""
    @State private var newPlayNumberTwo = ""
    @State private var newPlayNumberThree = ""
    @State private var lastSpokenPlayID: String?
    @FocusState private var focusedField: PlayFocusedField?

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

                Section(header: ListSectionHeader(title: "Add Category")) {
                    addCategoryRow
                }
                .catcherListRowBackground()

                Section(header: ListSectionHeader(title: "Add Play")) {
                    addPlayRow
                }
                .catcherListRowBackground()

                ForEach(categories) { category in
                    Section(header: ListSectionHeader(title: category.title)) {
                        if category.plays.isEmpty {
                            EmptyPlayCategoryRow()
                        } else {
                            ForEach(category.plays) { play in
                                VStack(alignment: .leading, spacing: 6) {
                                    PlayCallRow(play: play) {
                                        sendPlay(play)
                                    }

                                    if lastSpokenPlayID == play.id {
                                        SpokenMessageText(message: audio.lastMessage)
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button("Delete", role: .destructive) {
                                        deletePlay(play, from: category)
                                    }
                                }
                            }
                            .onMove { source, destination in
                                movePlays(in: category, from: source, to: destination)
                            }
                        }
                    }
                    .catcherListRowBackground()
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .navigationTitle("Plays")
            .toolbar {
                EditButton()
            }
            .onAppear(perform: normalizeSelectedCategory)
            .onChange(of: categories) { _, newValue in
                PlayCategory.saveCategories(newValue)
                normalizeSelectedCategory()
            }
            .appScreenBackground()
        }
    }

    private var addCategoryRow: some View {
        HStack {
            TextField("New category", text: $newCategoryTitle)
                .textInputAutocapitalization(.words)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .category)
                .submitLabel(.done)
                .onSubmit(addCategory)

            Button("Add") {
                addCategory()
            }
            .buttonStyle(.borderedProminent)
            .disabled(newCategoryTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private var addPlayRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Category", selection: $selectedCategoryID) {
                ForEach(categories) { category in
                    Text(category.title).tag(category.id)
                }
            }
            .pickerStyle(.menu)

            TextField("Play name", text: $newPlayTitle)
                .textInputAutocapitalization(.words)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .title)
                .submitLabel(.next)

            HStack(spacing: 8) {
                playNumberField("1", text: $newPlayNumberOne, field: .numberOne)
                playNumberField("2", text: $newPlayNumberTwo, field: .numberTwo)
                playNumberField("3", text: $newPlayNumberThree, field: .numberThree)

                Button("Add") {
                    addPlay()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canAddPlay)
            }
        }
    }

    private func playNumberField(
        _ placeholder: String,
        text: Binding<String>,
        field: PlayFocusedField
    ) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(.numberPad)
            .textFieldStyle(.roundedBorder)
            .focused($focusedField, equals: field)
            .frame(minWidth: 46)
    }

    private var canAddPlay: Bool {
        !newPlayTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !newPlayNumberOne.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !newPlayNumberTwo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !newPlayNumberThree.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var statusTitle: String {
        "Audio Ready"
    }

    private var statusIcon: String {
        "speaker.wave.2.fill"
    }

    private func addCategory() {
        let title = newCategoryTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }

        let category = PlayCategory.custom(title: title)
        focusedField = nil
        categories.append(category)
        selectedCategoryID = category.id
        newCategoryTitle = ""
    }

    private func addPlay() {
        let title = newPlayTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let numberOne = newPlayNumberOne.trimmingCharacters(in: .whitespacesAndNewlines)
        let numberTwo = newPlayNumberTwo.trimmingCharacters(in: .whitespacesAndNewlines)
        let numberThree = newPlayNumberThree.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !title.isEmpty, !numberOne.isEmpty, !numberTwo.isEmpty, !numberThree.isEmpty else {
            return
        }

        normalizeSelectedCategory()
        let play = PlayCallItem.custom(title: title, numbers: [numberOne, numberTwo, numberThree])

        guard let categoryIndex = categories.firstIndex(where: { $0.id == selectedCategoryID }) else {
            return
        }

        focusedField = nil
        categories[categoryIndex].plays.append(play)
        newPlayTitle = ""
        newPlayNumberOne = ""
        newPlayNumberTwo = ""
        newPlayNumberThree = ""
    }

    private func deletePlay(_ play: PlayCallItem, from category: PlayCategory) {
        guard let categoryIndex = categories.firstIndex(where: { $0.id == category.id }) else { return }
        categories[categoryIndex].plays.removeAll { $0.id == play.id }
    }

    private func movePlays(in category: PlayCategory, from source: IndexSet, to destination: Int) {
        guard let categoryIndex = categories.firstIndex(where: { $0.id == category.id }) else { return }

        withAnimation(.snappy) {
            categories[categoryIndex].plays.move(fromOffsets: source, toOffset: destination)
        }
    }

    private func normalizeSelectedCategory() {
        if categories.isEmpty {
            categories = [.defaultCategory]
        }

        if !categories.contains(where: { $0.id == selectedCategoryID }) {
            selectedCategoryID = categories.first?.id ?? PlayCategory.defaultCategoryID
        }
    }

    private func sendPlay(_ play: PlayCallItem) {
        guard let number = play.numbers.randomElement() else { return }
        lastSpokenPlayID = play.id
        audio.sendPlay(title: play.title, number: number)
    }
}

private enum PlayFocusedField: Hashable {
    case category
    case title
    case numberOne
    case numberTwo
    case numberThree
}

private struct PlayCategory: Identifiable, Equatable, Codable {
    let id: String
    let title: String
    var plays: [PlayCallItem]

    static let defaultCategoryID = "general"
    private static let storageKey = "catchercom.playCategories"
    private static let legacyPlayStorageKey = "catchercom.playOrder"

    static var defaultCategory: PlayCategory {
        PlayCategory(id: defaultCategoryID, title: "General", plays: [])
    }

    static func custom(title: String) -> PlayCategory {
        PlayCategory(
            id: UUID().uuidString,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            plays: []
        )
    }

    static func loadSavedCategories() -> [PlayCategory] {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let savedCategories = try? JSONDecoder().decode([PlayCategory].self, from: data),
           !savedCategories.isEmpty {
            return savedCategories
        }

        if let data = UserDefaults.standard.data(forKey: legacyPlayStorageKey),
           let legacyPlays = try? JSONDecoder().decode([PlayCallItem].self, from: data),
           !legacyPlays.isEmpty {
            return [PlayCategory(id: defaultCategoryID, title: "General", plays: legacyPlays)]
        }

        return [.defaultCategory]
    }

    static func saveCategories(_ categories: [PlayCategory]) {
        guard let data = try? JSONEncoder().encode(categories) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

private struct PlayCallItem: Identifiable, Equatable, Codable {
    let id: String
    let title: String
    let numbers: [String]

    static func custom(title: String, numbers: [String]) -> PlayCallItem {
        PlayCallItem(
            id: UUID().uuidString,
            title: title,
            numbers: numbers
        )
    }
}

private struct PlayCallRow: View {
    let play: PlayCallItem
    let onSend: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(play.title)
                    .font(.headline)

                Text(play.numbers.joined(separator: ", "))
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

private struct EmptyPlayCategoryRow: View {
    var body: some View {
        Text("No plays in this category")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
