import SwiftUI

struct PlaysView: View {
    // MARK: - Dependencies

    @ObservedObject var audio: CatcherAudioManager

    // MARK: - State

    // Categories own their plays so each section can be reordered and persisted independently.
    @State private var categories: [PlayCategory] = PlayCategory.loadSavedCategories()
    @AppStorage("catchercom.plays.selectedCategoryID") private var selectedCategoryID = PlayCategory.loadSavedCategories().first?.id ?? ""
    @State private var lastSpokenPlayID: String?
    @State private var editingPlay: PlayEditState?
    @State private var isShowingPlaySetup = false

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

                Section(header: ListSectionHeader(title: "Plays")) {
                    if categories.isEmpty {
                        EmptyPlaySetupRow()
                    } else {
                        ForEach(categories) { category in
                            PlayCategoryRow(category: category)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button("Delete", role: .destructive) {
                                        deleteCategory(category)
                                    }
                                }

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

                                        Button("Edit") {
                                            editingPlay = PlayEditState(play: play, categoryID: category.id, categories: categories)
                                        }
                                        .tint(.blue)
                                    }
                                }
                                .onMove { source, destination in
                                    movePlays(in: category, from: source, to: destination)
                                }
                            }
                        }
                    }
                }
                .catcherListRowBackground()
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .navigationTitle("Plays")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        isShowingPlaySetup = true
                    } label: {
                        Label("Add", systemImage: "plus")
                    }

                    EditButton()
                }
            }
            .onAppear(perform: normalizeSelectedCategory)
            .onChange(of: categories) { _, newValue in
                PlayCategory.saveCategories(newValue)
                normalizeSelectedCategory()
            }
            .sheet(item: $editingPlay) { editState in
                PlayEditView(editState: editState) { updatedPlay, categoryID in
                    updatePlay(updatedPlay, categoryID: categoryID)
                    editingPlay = nil
                } onCancel: {
                    editingPlay = nil
                }
            }
            .sheet(isPresented: $isShowingPlaySetup) {
                PlaySetupView(
                    categories: $categories,
                    selectedCategoryID: $selectedCategoryID
                )
            }
            .appScreenBackground()
        }
    }

    // MARK: - Audio Card

    private var statusTitle: String {
        "Audio Ready"
    }

    private var statusIcon: String {
        "speaker.wave.2.fill"
    }

    // MARK: - Actions

    private func deletePlay(_ play: PlayCallItem, from category: PlayCategory) {
        guard let categoryIndex = categories.firstIndex(where: { $0.id == category.id }) else { return }
        categories[categoryIndex].plays.removeAll { $0.id == play.id }
    }

    private func deleteCategory(_ category: PlayCategory) {
        categories.removeAll { $0.id == category.id }
    }

    private func updatePlay(_ play: PlayCallItem, categoryID: String) {
        var originalCategoryID: String?
        var originalPlayIndex: Int?

        // Remove the play from its current category first, then insert it into the selected category.
        for categoryIndex in categories.indices {
            if let playIndex = categories[categoryIndex].plays.firstIndex(where: { $0.id == play.id }) {
                originalCategoryID = categories[categoryIndex].id
                originalPlayIndex = playIndex
                categories[categoryIndex].plays.remove(at: playIndex)
                break
            }
        }

        let targetCategoryID = categories.contains(where: { $0.id == categoryID }) ? categoryID : (categories.first?.id ?? "")
        guard let targetCategoryIndex = categories.firstIndex(where: { $0.id == targetCategoryID }) else { return }

        if originalCategoryID == targetCategoryID, let originalPlayIndex {
            categories[targetCategoryIndex].plays.insert(
                play,
                at: min(originalPlayIndex, categories[targetCategoryIndex].plays.count)
            )
        } else {
            categories[targetCategoryIndex].plays.append(play)
        }
    }

    private func movePlays(in category: PlayCategory, from source: IndexSet, to destination: Int) {
        guard let categoryIndex = categories.firstIndex(where: { $0.id == category.id }) else { return }

        withAnimation(.snappy) {
            categories[categoryIndex].plays.move(fromOffsets: source, toOffset: destination)
        }
    }

    private func normalizeSelectedCategory() {
        // If the selected category was deleted, fall back to the first available category.
        if !categories.contains(where: { $0.id == selectedCategoryID }) {
            selectedCategoryID = categories.first?.id ?? ""
        }
    }

    private func sendPlay(_ play: PlayCallItem) {
        // Plays can have one to three numbers; choose randomly so the spoken code changes.
        guard let number = play.numbers.randomElement() else { return }
        lastSpokenPlayID = play.id
        audio.sendPlay(title: play.title, number: number)
    }
}
