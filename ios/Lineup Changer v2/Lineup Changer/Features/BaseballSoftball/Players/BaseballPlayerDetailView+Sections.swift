// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BaseballPlayerDetailView+Sections.swift
//
//
//
import SwiftUI

// MARK: - Baseball Player Detail Sections
extension BaseballPlayerDetailView {
    @ViewBuilder
    var playerFormSections: some View {
        playerProfileSection
        notesSection
        stealAbilitySection
        addPositionSection
        currentPositionsSection
        ratingScaleSection
    }

    private var playerProfileSection: some View {
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

            if !isPhoneNumberValidOrEmpty(editedCellNumber) {
                Text("Cell # must contain exactly 10 digits.")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
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

    private var notesSection: some View {
        Section("Notes") {
            TextEditor(text: $editedNotes)
                .focused($focusedField, equals: .notes)
                .frame(minHeight: 100)
        }
    }

    private var stealAbilitySection: some View {
        Section("Steal Ability") {
            Picker("Steal Ability", selection: $selectedSpeedRating) {
                Label("Steal", systemImage: "figure.run").tag(1)
                Label("No Steal", systemImage: "hand.raised.fill").tag(2)
            }
            .pickerStyle(.segmented)
        }
    }

}
