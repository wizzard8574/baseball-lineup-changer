import SwiftUI
import Foundation

private enum NotesGroup: String, CaseIterable, Identifiable {
    case players = "Players"
    case coaches = "Coaches"

    var id: String { rawValue }
}

struct NotesView: View {
    @ObservedObject var viewModel: LineupViewModel
    @FocusState private var isEditing: Bool
    @State private var selectedNotesGroup: NotesGroup = .players
    // coach notes are persisted in viewModel.coachNotes
    
    private var allContactNumbers: [String] {
        viewModel.players.map(\.cell) + viewModel.coaches.map(\.cell)
    }
    
    private var sortedPlayers: [Player] {
        viewModel.players.sorted { lhs, rhs in
            let lhsNumber = Int(lhs.number)
            let rhsNumber = Int(rhs.number)
            
            switch (lhsNumber, rhsNumber) {
            case let (l?, r?):
                return l < r
            case (nil, nil):
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            case (nil, _?):
                return false
            case (_?, nil):
                return true
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                VStack(spacing: 8) {
                    Picker("Notes Group", selection: $selectedNotesGroup) {
                        ForEach(NotesGroup.allCases) { group in
                            Text(group.rawValue).tag(group)
                        }
                    }
                    .pickerStyle(.segmented)

                    if selectedNotesGroup == .players {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Pre Game Notes")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                if let url = groupTextURL(for: allContactNumbers, body: preGameTextMessage) {
                                    Link(destination: url) {
                                        Label("Text Team", systemImage: "message.fill")
                                    }
                                    .font(.caption.weight(.semibold))
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                }

                                Button {
                                    viewModel.preGameNotes = ""
                                } label: {
                                    Label("Clear", systemImage: "xmark.circle")
                                }
                                .font(.caption.weight(.semibold))
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .tint(.secondary)
                                .disabled(viewModel.preGameNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }

                            TextEditor(text: preGameNotesBinding)
                                .focused($isEditing)
                                .padding(6)
                                .frame(height: max(140, (geo.size.height - 170) / 2))
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Post Game Notes")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                if let url = groupTextURL(for: allContactNumbers, body: postGameTextMessage) {
                                    Link(destination: url) {
                                        Label("Text Team", systemImage: "message.fill")
                                    }
                                    .font(.caption.weight(.semibold))
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                }

                                Button {
                                    viewModel.postGameNotes = ""
                                } label: {
                                    Label("Clear", systemImage: "xmark.circle")
                                }
                                .font(.caption.weight(.semibold))
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .tint(.secondary)
                                .disabled(viewModel.postGameNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }

                            TextEditor(text: postGameNotesBinding)
                                .focused($isEditing)
                                .padding(6)
                                .frame(height: max(140, (geo.size.height - 170) / 2))
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                        }
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Coaches Notes")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                if let url = groupTextURL(for: viewModel.coaches.map(\.cell), body: coachesTextMessage) {
                                    Link(destination: url) {
                                        Label("Text Coaches", systemImage: "message.fill")
                                    }
                                    .font(.caption.weight(.semibold))
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                }

                                Button {
                                    viewModel.coachNotes = ""
                                } label: {
                                    Label("Clear", systemImage: "xmark.circle")
                                }
                                .font(.caption.weight(.semibold))
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .tint(.secondary)
                                .disabled(viewModel.coachNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }

                            TextEditor(text: $viewModel.coachNotes)
                                .focused($isEditing)
                                .padding(6)
                                .frame(height: max(240, geo.size.height - 120))
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 8)
            }
            .navigationTitle("Notes")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isEditing = false
                    }
                }
            }
        }
    }

    private var preGameTextMessage: String {
        """
        Pre Game Notes:
        \(viewModel.preGameNotes)
        """
    }

    private var postGameTextMessage: String {
        """
        Post Game Notes:
        \(viewModel.postGameNotes)
        """
    }

    private var coachesTextMessage: String {
        """
        Coaches Notes:
        \(viewModel.coachNotes)
        """
    }

    private var preGameNotesBinding: Binding<String> {
        switch selectedNotesGroup {
        case .players:
            return $viewModel.preGameNotes
        case .coaches:
            return $viewModel.coachNotes
        }
    }

    private var postGameNotesBinding: Binding<String> {
        switch selectedNotesGroup {
        case .players:
            return $viewModel.postGameNotes
        case .coaches:
            return .constant("")
        }
    }
}
