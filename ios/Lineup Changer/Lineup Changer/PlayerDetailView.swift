//
//  PlayerDetailView.swift
//  Lineup Changer
//
//  Created by Rich Morris on 5/2/26.
//

import SwiftUI

// MARK: - Player Detail

private enum PlayerDetailFocusedField: Hashable {
    case name
    case number
    case cell
    case notes
}

struct PlayerDetailView: View {
    @ObservedObject var viewModel: LineupViewModel
    let player: Player
    
    @State private var editedName: String = ""
    @State private var editedNumber: String = ""
    @State private var editedCellNumber: String = ""
    @State private var selectedSpeedRating: Int = 1
    @State private var selectedPosition: FieldPosition = .firstBase
    @State private var selectedRating: Int = 1
    @State private var editedNotes: String = ""
    @FocusState private var focusedField: PlayerDetailFocusedField?
    @Environment(\.dismiss) private var dismiss
    
    private var currentPlayer: Player? {
        viewModel.players.first(where: { $0.id == player.id })
    }

    private var availablePositions: [FieldPosition] {
        FieldPosition.allCases.filter { position in
            !(currentPlayer?.positionRatings.keys.contains(position) ?? false)
        }
    }
    
    var body: some View {
        Form {
            Section("Player") {
                TextField("Name", text: $editedName)
                    .focused($focusedField, equals: .name)
                    .submitLabel(.done)
                    .onSubmit {
                        savePlayerInfo()
                        focusedField = nil
                    }
                
                TextField("Number", text: $editedNumber)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .number)
                    .submitLabel(.done)
                    .onSubmit {
                        savePlayerInfo()
                        focusedField = nil
                    }
                
                HStack {
                    TextField("Cell #", text: $editedCellNumber)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .cell)
                        .submitLabel(.done)
                        .onChange(of: editedCellNumber) { oldValue, newValue in
                            editedCellNumber = normalizedPhoneInput(oldValue: oldValue, newValue: newValue)
                        }
                        .onSubmit {
                            savePlayerInfo()
                            focusedField = nil
                        }

                    if phoneDigits(editedCellNumber).count == 10 {
                        if let callURL = phoneCallURL(for: editedCellNumber) {
                            Link(destination: callURL) {
                                Image(systemName: "phone.fill")
                                    .foregroundStyle(.blue)
                            }
                        }

                        if let textURL = phoneTextURL(for: editedCellNumber) {
                            Link(destination: textURL) {
                                Image(systemName: "message.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
                
                if !isPhoneNumberValidOrEmpty(editedCellNumber) {
                    Text("Cell # must contain exactly 10 digits.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                
            }
            
            Section("Notes") {
                TextEditor(text: $editedNotes)
                    .focused($focusedField, equals: .notes)
                    .frame(minHeight: 100)
            }
            
            Section("Steal Ability") {
                Picker("Steal Ability", selection: $selectedSpeedRating) {
                    Label("Steal", systemImage: "figure.run").tag(1)
                    Label("No Steal", systemImage: "hand.raised.fill").tag(2)
                }
                .pickerStyle(.segmented)
            }
            
            Section("Add or Update Position") {
                if availablePositions.isEmpty {
                    Text("All positions already assigned.")
                        .foregroundStyle(.secondary)
                } else {
                    Picker("Position", selection: $selectedPosition) {
                        ForEach(availablePositions) { position in
                            Text(position.rawValue).tag(position)
                        }
                    }
                }

                if !availablePositions.isEmpty {
                    Picker("Rating", selection: $selectedRating) {
                        ForEach(1...5, id: \.self) { rating in
                            Text("\(rating)").tag(rating)
                        }
                    }

                    Button("Save Position") {
                        viewModel.setRating(playerID: player.id, position: selectedPosition, rating: selectedRating)
                        selectFirstAvailablePosition()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            
            Section("Current Positions") {
                if let currentPlayer, currentPlayer.positionRatings.isEmpty {
                    Text("No positions added yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(FieldPosition.allCases) { position in
                        if let rating = currentPlayer?.positionRatings[position] {
                            HStack {
                                Text(position.rawValue)
                                    .fontWeight(.semibold)
                                Spacer()
                                Picker("Rating", selection: Binding(
                                    get: { rating },
                                    set: { newRating in
                                        viewModel.setRating(playerID: player.id, position: position, rating: newRating)
                                    }
                                )) {
                                    ForEach(1...5, id: \.self) { rating in
                                        Text("\(rating)").tag(rating)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                            .swipeActions {
                                Button("Remove", role: .destructive) {
                                    viewModel.removePosition(playerID: player.id, position: position)
                                }
                            }
                        }
                    }
                }
            }
            
            Section("Scale") {
                Text("1 = High, 5 = Low. A player is only considered for positions listed here.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(currentPlayer?.name ?? player.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    savePlayerInfo()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isPhoneNumberValidOrEmpty(editedCellNumber))
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    savePlayerInfo()
                    focusedField = nil
                }
            }
        }
        .onAppear {
            editedName = currentPlayer?.name ?? player.name
            editedNumber = currentPlayer?.number ?? player.number
            editedCellNumber = currentPlayer?.cell ?? player.cell
            selectedSpeedRating = currentPlayer?.speedRating ?? player.speedRating
            editedNotes = currentPlayer?.notes ?? player.notes

            selectFirstAvailablePosition()
        }
    }
    
    private func selectFirstAvailablePosition() {
        if let first = availablePositions.first {
            selectedPosition = first
        }
    }

    private func savePlayerInfo() {
        guard isPhoneNumberValidOrEmpty(editedCellNumber) else { return }
        viewModel.renamePlayer(playerID: player.id, newName: editedName)
        viewModel.updatePlayerNumber(playerID: player.id, newNumber: editedNumber)
        viewModel.updatePlayerCell(playerID: player.id, newCell: editedCellNumber)
        viewModel.updatePlayerSpeed(playerID: player.id, speedRating: selectedSpeedRating)
        viewModel.updatePlayerNotes(playerID: player.id, notes: editedNotes)
    }
    
}
