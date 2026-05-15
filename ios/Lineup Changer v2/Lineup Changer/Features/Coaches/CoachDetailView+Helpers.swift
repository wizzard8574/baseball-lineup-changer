// Created by Rich Morris on 5/5/26.
// Lineup Changer
// CoachDetailView+Helpers.swift
//
//
//
import SwiftUI
import MessageUI

// MARK: - Coach Detail Helpers
extension CoachDetailView {
    // MARK: - Message Composer
    // Validates the cell number and device capability before showing the message composer.
    func presentMessageComposer() {
        let recipient = phoneDigits(editedCellNumber)

        // Require a complete 10-digit number before texting.
        guard recipient.count == 10 else {
            messageAlertText = "This coach does not have a valid 10-digit cell number."
            return
        }

        // Some devices, such as simulators or iPads without SMS support, cannot send texts.
        guard MFMessageComposeViewController.canSendText() else {
            messageAlertText = "Text messaging is not available on this device."
            return
        }

        isShowingMessageComposer = true
    }

    // MARK: - Load Coach Info
    // Populates the editable form state from the latest saved coach values.
    func loadCoachInfo() {
        editedName = currentCoach?.name ?? coach.name
        editedNumber = currentCoach?.number ?? coach.number
        selectedRole = CoachRoleOption(rawValue: currentCoach?.role ?? coach.role) ?? .assistantCoach

        // If the saved role is no longer allowed, fall back to Assistant Coach.
        if !availableRoleOptions.contains(selectedRole) {
            selectedRole = .assistantCoach
        }

        editedCellNumber = currentCoach?.cell ?? coach.cell
    }

    // MARK: - Save Coach Info
    // Writes valid form values back to the view model.
    // The view model methods are responsible for updating stored coach data.
    func saveCoachInfo() {
        // Do not save while the cell number is invalid.
        guard isPhoneNumberValidOrEmpty(editedCellNumber) else { return }
        viewModel.updateCoachName(coachID: coach.id, newName: editedName)
        viewModel.updateCoachNumber(coachID: coach.id, newNumber: editedNumber)
        viewModel.updateCoachRole(coachID: coach.id, newRole: selectedRole.rawValue)
        viewModel.updateCoachCell(coachID: coach.id, newCell: editedCellNumber)
    }
}
