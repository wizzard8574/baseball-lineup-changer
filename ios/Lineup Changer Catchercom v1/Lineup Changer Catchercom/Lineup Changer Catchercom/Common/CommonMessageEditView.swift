import SwiftUI

// MARK: - Common Editing

struct CommonMessageEditState: Identifiable {
    let id: String
    var title: String
    var location: CatcherLocation

    init(item: CommonMessageItem) {
        id = item.id
        title = item.title
        location = item.location
    }
}

struct CommonMessageEditView: View {
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
