import SwiftUI
import Foundation
import MessageUI

private enum NotesGroup: String, CaseIterable, Identifiable {
    case players = "Players"
    case coaches = "Coaches"

    var id: String { rawValue }
}

private struct TextMessageDraft: Identifiable {
    let id = UUID()
    let recipients: [String]
    let body: String
}

struct NotesView: View {
    @ObservedObject var viewModel: LineupViewModel
    @FocusState private var isEditing: Bool
    @State private var selectedNotesGroup: NotesGroup = .players
    @State private var messageDraft: TextMessageDraft?
    @State private var messageAlertText: String?
    // coach notes are persisted in viewModel.coachNotes
    
    private var allContactNumbers: [String] {
        viewModel.players.map(\.cell) + viewModel.coaches.map(\.cell)
    }

    private var allTeamRecipients: [String] {
        validRecipients(from: allContactNumbers)
    }

    private var coachRecipients: [String] {
        validRecipients(from: viewModel.coaches.map(\.cell))
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
            ZStack {
                AppSportsBackground()

                GeometryReader { geo in
                VStack(spacing: 8) {
                    TeamPickerView(viewModel: viewModel)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(Color(uiColor: .systemBackground).opacity(0.92), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                        .padding(.horizontal)

                    Picker("Notes Group", selection: $selectedNotesGroup) {
                        ForEach(NotesGroup.allCases) { group in
                            Text(group.rawValue).tag(group)
                        }
                    }
                    .pickerStyle(.segmented)

                    if selectedNotesGroup == .players {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                notesSectionHeader("Pre Game Notes")

                                Spacer()

                                Button {
                                    presentMessageComposer(recipients: allTeamRecipients, body: preGameTextMessage)
                                } label: {
                                    Label("Text Team", systemImage: "message.fill")
                                }
                                .font(.caption.weight(.semibold))
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                                .disabled(allTeamRecipients.isEmpty)

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
                                notesSectionHeader("Post Game Notes")

                                Spacer()

                                Button {
                                    presentMessageComposer(recipients: allTeamRecipients, body: postGameTextMessage)
                                } label: {
                                    Label("Text Team", systemImage: "message.fill")
                                }
                                .font(.caption.weight(.semibold))
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                                .disabled(allTeamRecipients.isEmpty)

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
                                notesSectionHeader("Coaches Notes")

                                Spacer()

                                Button {
                                    presentMessageComposer(recipients: coachRecipients, body: coachesTextMessage)
                                } label: {
                                    Label("Text Coaches", systemImage: "message.fill")
                                }
                                .font(.caption.weight(.semibold))
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                                .disabled(coachRecipients.isEmpty)

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
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 10) {
                        Image(systemName: "note.text")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.45), radius: 2, x: 0, y: 1)

                        Text("Notes")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.25), in: Capsule())
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isEditing = false
                    }
                }
            }
            .sheet(item: $messageDraft) { draft in
                MessageComposerView(recipients: draft.recipients, body: draft.body)
            }
            .alert("Unable to Text", isPresented: Binding(
                get: { messageAlertText != nil },
                set: { if !$0 { messageAlertText = nil } }
            )) {
                Button("OK", role: .cancel) { messageAlertText = nil }
            } message: {
                Text(messageAlertText ?? "")
            }
        }
    }

    private func notesSectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .textCase(nil)
            .shadow(color: .black.opacity(0.45), radius: 2, x: 0, y: 1)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.black.opacity(0.22), in: Capsule())
    }

    private func validRecipients(from numbers: [String]) -> [String] {
        Array(Set(numbers.map { phoneDigits($0) }.filter { $0.count == 10 })).sorted()
    }

    private func presentMessageComposer(recipients: [String], body: String) {
        guard !recipients.isEmpty else {
            messageAlertText = "No valid 10-digit cell numbers were found."
            return
        }

        guard MFMessageComposeViewController.canSendText() else {
            messageAlertText = "Text messaging is not available on this device."
            return
        }

        messageDraft = TextMessageDraft(recipients: recipients, body: body)
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
