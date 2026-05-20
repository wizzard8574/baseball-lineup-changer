import SwiftUI

// MARK: - Pitch Editing

struct PitchEditState: Identifiable {
    let id: String
    var title: String

    init(item: PitchCallItem) {
        id = item.id
        title = item.title
    }
}

struct PitchEditView: View {
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
