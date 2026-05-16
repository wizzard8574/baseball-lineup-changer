// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BasketballPlayerDetailView+Helpers.swift
//
//
//
import Foundation
import SwiftUI
import MessageUI

extension BasketballPlayerDetailView {
    var basketballPlayerDetailTitle: some View {
        AppToolbarTitle(
            title: playerTitle.isEmpty ? "Player" : playerTitle,
            systemImage: "person.fill",
            isCompact: true
        )
    }

    func saveAndClearFocus() {
        savePlayerInfo()
        focusedField = nil
    }

    func presentMessageComposer() {
        let recipient = phoneDigits(editedCellNumber)

        guard recipient.count == 10 else {
            messageAlertText = "This player does not have a valid 10-digit cell number."
            return
        }

        guard MFMessageComposeViewController.canSendText() else {
            messageAlertText = "Text messaging is not available on this device."
            return
        }

        isShowingMessageComposer = true
    }

    func loadPlayerInfo() {
        editedName = currentPlayer?.name ?? player.name
        editedNumber = currentPlayer?.number ?? player.number
        editedCellNumber = currentPlayer?.cell ?? player.cell
        isGuestPlayer = (currentPlayer?.status ?? player.status) == .guest
        editedNotes = currentPlayer?.notes ?? player.notes
        selectFirstAvailableBasketballPosition()
    }

    func selectFirstAvailableBasketballPosition() {
        if let first = availableBasketballPositions.first {
            selectedBasketballPosition = first
        }
    }

    func isDuplicateNonGuestNumber(_ number: String) -> Bool {
        let trimmedNumber = number.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNumber.isEmpty, !isGuestPlayer else { return false }

        return viewModel.players.contains { otherPlayer in
            otherPlayer.id != player.id
            && otherPlayer.status != .guest
            && otherPlayer.number.trimmingCharacters(in: .whitespacesAndNewlines) == trimmedNumber
        }
    }

    func savePlayerInfo() {
        duplicateNumberAlertText = nil

        guard isPhoneNumberValidOrEmpty(editedCellNumber) else { return }

        if isDuplicateNonGuestNumber(editedNumber) {
            duplicateNumberAlertText = "A non-guest player with number #\(editedNumber) already exists. Set this player to Guest if they are using the same number."
            return
        }

        viewModel.updateBasketballPlayerProfile(
            playerID: player.id,
            name: editedName,
            number: editedNumber,
            cell: editedCellNumber,
            notes: editedNotes,
            status: isGuestPlayer ? .guest : .active
        )
    }
}
