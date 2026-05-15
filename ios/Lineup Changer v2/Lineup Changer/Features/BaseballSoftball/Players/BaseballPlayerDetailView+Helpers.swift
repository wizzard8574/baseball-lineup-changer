// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BaseballPlayerDetailView+Helpers.swift
//
//
//
import SwiftUI
import MessageUI

// MARK: - Baseball Player Detail Helpers
extension BaseballPlayerDetailView {
    var playerDetailTitle: some View {
        AppToolbarTitle(
            title: playerTitle.isEmpty ? "Player" : playerTitle,
            systemImage: "person.fill",
            isCompact: true
        )
    }
    // MARK: - Private Actions
    func saveAndClearFocus() {
        savePlayerInfo()
        focusedField = nil
    }

    // Validates the cell number and device capability before showing the message composer.
    func presentMessageComposer() {
        let recipient = phoneDigits(editedCellNumber)
        
        // Require a complete 10-digit number before texting.
        guard recipient.count == 10 else {
            messageAlertText = "This player does not have a valid 10-digit cell number."
            return
        }
        
        // Some devices, such as simulators or iPads without SMS support, cannot send texts.
        guard MFMessageComposeViewController.canSendText() else {
            messageAlertText = "Text messaging is not available on this device."
            return
        }
        
        isShowingMessageComposer = true
    }
    
    // Selects the first unrated position so the add-position picker always has a valid value.
    func selectFirstAvailablePosition() {
        if let first = availablePositions.first {
            selectedPosition = first
        }
    }
    
    // Checks whether another non-guest player already uses this jersey number.
    func isDuplicateNonGuestNumber(_ number: String) -> Bool {
        // Blank jersey numbers are allowed and are not treated as duplicates.
        let trimmedNumber = number.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNumber.isEmpty else { return false }
        
        // Guests are allowed to reuse numbers, so only non-guest players are compared.
        return viewModel.players.contains { otherPlayer in
            otherPlayer.id != player.id
            && otherPlayer.status != .guest
            && otherPlayer.number.trimmingCharacters(in: .whitespacesAndNewlines) == trimmedNumber
        }
    }
    
    // Writes valid form values back to the view model.
    func savePlayerInfo() {
        // Do not save while the cell number is invalid.
        guard isPhoneNumberValidOrEmpty(editedCellNumber) else { return }
        // Prevent duplicate jersey numbers for non-guest players.
        if !isGuestPlayer, isDuplicateNonGuestNumber(editedNumber) {
            duplicateNumberAlertText = "A non-guest player with number #\(editedNumber) already exists. Check Guest if this is a guest player using the same number."
            return
        }
        // Persist all edited player fields through view-model update methods.
        viewModel.renamePlayer(playerID: player.id, newName: editedName)
        viewModel.updatePlayerNumber(playerID: player.id, newNumber: editedNumber)
        viewModel.updatePlayerCell(playerID: player.id, newCell: editedCellNumber)
        viewModel.updatePlayerSpeed(playerID: player.id, speedRating: selectedSpeedRating)
        viewModel.updatePlayerNotes(playerID: player.id, notes: editedNotes)
        viewModel.setPlayerStatus(playerID: player.id, status: isGuestPlayer ? .guest : .active)
    }

    func loadPlayerInfo() {
        editedName = currentPlayer?.name ?? player.name
        editedNumber = currentPlayer?.number ?? player.number
        editedCellNumber = currentPlayer?.cell ?? player.cell
        isGuestPlayer = (currentPlayer?.status ?? player.status) == .guest
        selectedSpeedRating = currentPlayer?.speedRating ?? player.speedRating
        editedNotes = currentPlayer?.notes ?? player.notes
        selectFirstAvailablePosition()
    }
}
