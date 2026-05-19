//
//  PlayEditView.swift
//  Lineup Changer Catchercom
//
//  Created by Rich Morris on 5/18/26.
//
import SwiftUI

struct PlayEditView: View {
    // MARK: - State

    @State private var editState: PlayEditState

    // MARK: - Callbacks

    let onSave: (PlayCallItem, String) -> Void
    let onCancel: () -> Void

    // MARK: - Initialization

    init(
        editState: PlayEditState,
        onSave: @escaping (PlayCallItem, String) -> Void,
        onCancel: @escaping () -> Void
    ) {
        _editState = State(initialValue: editState)
        self.onSave = onSave
        self.onCancel = onCancel
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section("Play") {
                    TextField("Name", text: $editState.title)
                        .textInputAutocapitalization(.words)

                    Picker("Category", selection: $editState.categoryID) {
                        ForEach(editState.categories) { category in
                            Text(category.title).tag(category.id)
                        }
                    }
                }

                Section("Numbers") {
                    TextField("1", text: $editState.numberOne)
                        .keyboardType(.numberPad)
                    TextField("2", text: $editState.numberTwo)
                        .keyboardType(.numberPad)
                    TextField("3", text: $editState.numberThree)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Edit Play")
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
                                numbers: [
                                    editState.numberOne,
                                    editState.numberTwo,
                                    editState.numberThree
                                ]
                            ),
                            editState.categoryID
                        )
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    // MARK: - Validation

    private var canSave: Bool {
        !editState.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !editState.numberOne.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
