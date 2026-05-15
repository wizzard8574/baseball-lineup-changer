// Created by Rich Morris on 5/5/26.
// Lineup Changer
// CoachDetailView+Sections.swift
//
//
//
import SwiftUI

// MARK: - Coach Detail Sections
extension CoachDetailView {
    var coachFormSection: some View {
        Section("Coach") {
            coachNameField
            coachNumberField
            coachRolePicker
            coachCellNumberRow
            cellNumberValidationMessage
        }
    }

    private var coachNameField: some View {
        TextField("Name", text: $editedName)
            .focused($focusedField, equals: .name)
            .submitLabel(.done)
            .onSubmit {
                saveCoachInfo()
                focusedField = nil
            }
    }

    private var coachNumberField: some View {
        TextField("Number", text: $editedNumber)
            .keyboardType(.numberPad)
            .focused($focusedField, equals: .number)
            .submitLabel(.done)
            .onSubmit {
                saveCoachInfo()
                focusedField = nil
            }
    }

    private var coachRolePicker: some View {
        Picker("Role", selection: $selectedRole) {
            ForEach(availableRoleOptions) { role in
                Text(role.rawValue).tag(role)
            }
        }
        .pickerStyle(.menu)
    }

    private var coachCellNumberRow: some View {
        HStack {
            TextField("Cell #", text: $editedCellNumber)
                .keyboardType(.numberPad)
                .focused($focusedField, equals: .cell)
                .submitLabel(.done)
                // Normalize phone input as the user types.
                .onChange(of: editedCellNumber) { oldValue, newValue in
                    editedCellNumber = normalizedPhoneInput(oldValue: oldValue, newValue: newValue)
                }
                .onSubmit {
                    saveCoachInfo()
                    focusedField = nil
                }

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
}
