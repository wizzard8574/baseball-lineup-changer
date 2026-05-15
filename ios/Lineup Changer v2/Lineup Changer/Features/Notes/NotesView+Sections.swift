// Created by Rich Morris on 5/5/26.
// Lineup Changer
// NotesView+Sections.swift
//
//
//
import SwiftUI

// MARK: - Notes Sections
extension NotesView {
    func notesFormContent(geometry geo: GeometryProxy) -> some View {
        VStack(spacing: 8) {
            teamPickerSection
            notesGroupPicker

            if selectedNotesGroup == .players {
                playerNotesSections(geometry: geo)
            } else {
                coachNotesSection(geometry: geo)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    private var teamPickerSection: some View {
        TeamPickerView(viewModel: viewModel)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(Color(uiColor: .systemBackground).opacity(0.92), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .padding(.horizontal)
    }

    private var notesGroupPicker: some View {
        Picker("Notes Group", selection: $selectedNotesGroup) {
            ForEach(NotesGroup.allCases) { group in
                Text(group.rawValue).tag(group)
            }
        }
        .pickerStyle(.segmented)
    }

    private func playerNotesSections(geometry geo: GeometryProxy) -> some View {
        VStack(spacing: 8) {
            preGameNotesSection(geometry: geo)
            postGameNotesSection(geometry: geo)
        }
    }

    private func preGameNotesSection(geometry geo: GeometryProxy) -> some View {
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
    }

    private func postGameNotesSection(geometry geo: GeometryProxy) -> some View {
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
    }

    private func coachNotesSection(geometry geo: GeometryProxy) -> some View {
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
