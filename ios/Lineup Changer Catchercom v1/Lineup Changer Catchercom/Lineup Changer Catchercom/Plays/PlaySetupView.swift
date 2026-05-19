//
//  PlaySetupView.swift
//  Lineup Changer Catchercom
//
//  Created by Rich Morris on 5/18/26.
//

import SwiftUI

struct PlaySetupView: View {
    // MARK: - Bindings

    @Binding var categories: [PlayCategory]
    @Binding var selectedCategoryID: String

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Form State

    @State private var newCategoryTitle = ""
    @State private var newPlayTitle = ""
    @State private var numberOne = ""
    @State private var numberTwo = ""
    @State private var numberThree = ""

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    HStack {
                        TextField("New category", text: $newCategoryTitle)
                            .textInputAutocapitalization(.words)

                        Button("Add") {
                            addCategory()
                        }
                        .disabled(newCategoryTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                Section("Play") {
                    if categories.isEmpty {
                        Text("Create a category before adding plays.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Category", selection: $selectedCategoryID) {
                            ForEach(categories) { category in
                                Text(category.title).tag(category.id)
                            }
                        }
                    }

                    TextField("Play name", text: $newPlayTitle)
                        .textInputAutocapitalization(.words)

                    TextField("1", text: $numberOne)
                        .keyboardType(.numberPad)
                    TextField("2", text: $numberTwo)
                        .keyboardType(.numberPad)
                    TextField("3", text: $numberThree)
                        .keyboardType(.numberPad)

                    Button("Add Play") {
                        addPlay()
                    }
                    .disabled(!canAddPlay)
                }
            }
            .navigationTitle("Add Plays")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear(perform: normalizeSelection)
            .onChange(of: categories) { _, _ in
                normalizeSelection()
            }
        }
    }

    // MARK: - Validation

    private var canAddPlay: Bool {
        !categories.isEmpty &&
        !newPlayTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !numberOne.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        categories.contains(where: { $0.id == selectedCategoryID })
    }

    // MARK: - Actions

    private func addCategory() {
        let title = newCategoryTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }

        let category = PlayCategory.custom(title: title)
        categories.append(category)
        selectedCategoryID = category.id
        newCategoryTitle = ""
    }

    private func addPlay() {
        guard let categoryIndex = categories.firstIndex(where: { $0.id == selectedCategoryID }) else {
            return
        }

        let play = PlayCallItem.custom(
            title: newPlayTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            numbers: [
                numberOne.trimmingCharacters(in: .whitespacesAndNewlines),
                numberTwo.trimmingCharacters(in: .whitespacesAndNewlines),
                numberThree.trimmingCharacters(in: .whitespacesAndNewlines)
            ]
        )

        categories[categoryIndex].plays.append(play)
        newPlayTitle = ""
        numberOne = ""
        numberTwo = ""
        numberThree = ""
    }

    // MARK: - Selection

    private func normalizeSelection() {
        if !categories.contains(where: { $0.id == selectedCategoryID }) {
            selectedCategoryID = categories.first?.id ?? ""
        }
    }
}
