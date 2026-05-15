// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BasketballPlayerDetailView+Sections.swift
//
//
//
import SwiftUI

extension BasketballPlayerDetailView {
    var playerProfileSection: some View {
        Section("Player") {
            TextField("Name", text: $editedName)
                .focused($focusedField, equals: .name)
                .submitLabel(.done)
                .onSubmit(saveAndClearFocus)

            TextField("Number", text: $editedNumber)
                .keyboardType(.numberPad)
                .focused($focusedField, equals: .number)
                .submitLabel(.done)
                .onSubmit(saveAndClearFocus)

            cellNumberRow

            Toggle("Guest", isOn: $isGuestPlayer)

            cellNumberValidationMessage
        }
    }

    private var cellNumberRow: some View {
        HStack {
            TextField("Cell #", text: $editedCellNumber)
                .keyboardType(.numberPad)
                .focused($focusedField, equals: .cell)
                .submitLabel(.done)
                .onChange(of: editedCellNumber) { oldValue, newValue in
                    editedCellNumber = normalizedPhoneInput(oldValue: oldValue, newValue: newValue)
                }
                .onSubmit(saveAndClearFocus)

            PhoneContactButtons(number: editedCellNumber, onText: presentMessageComposer)
        }
    }

    @ViewBuilder
    private var cellNumberValidationMessage: some View {
        if !isPhoneNumberValidOrEmpty(editedCellNumber) {
            Text("Cell # must contain exactly 10 digits.")
                .font(.caption)
                .foregroundStyle(.red)
        }
    }

    var notesSection: some View {
        Section("Notes") {
            TextEditor(text: $editedNotes)
                .focused($focusedField, equals: .notes)
                .frame(minHeight: 100)
        }
    }

    var gameChangerStatsSection: some View {
        Section("GameChanger Stats") {
            if let stats = currentPlayer?.basketballGameChangerStats {
                statRow("PPG", stats.ppg)
                statRow("TOPG", stats.topg)
                statRow("RPG", stats.rpg)
                statRow("APG", stats.apg)
                statRow("SPG", stats.spg)
                statRow("BPG", stats.bpg)
                statRow("TS%", stats.trueShootingPercentage)
                statRow("AST/TO", stats.assistTurnoverRatio)
            } else {
                Text("No GameChanger stats imported.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .fontWeight(.semibold)
            Spacer()
            Text(value.isEmpty ? "-" : value)
                .foregroundStyle(.secondary)
        }
    }
}
