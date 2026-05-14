// Created by Rich Morris on 5/5/26.
// Lineup Changer
// TeamPickerView.swift
//
//
//
import SwiftUI

// MARK: - Team Picker View

// Segmented picker for switching between the app's two team slots.
struct TeamPickerView: View {
    // Shared app state containing selected team and team names.
    @ObservedObject var viewModel: LineupViewModel

    // Picker selection writes through to selectTeam so team snapshots are saved/restored.
    var body: some View {
        Picker("Team", selection: Binding(
            get: { viewModel.selectedTeamIndex },
            set: { viewModel.selectTeam($0) }
        )) {
            // Fallback labels protect against malformed saved teamNames arrays.
            Text(viewModel.teamNames.indices.contains(0) ? viewModel.teamNames[0] : "Team 1").tag(0)
            Text(viewModel.teamNames.indices.contains(1) ? viewModel.teamNames[1] : "Team 2").tag(1)
        }
        .pickerStyle(.segmented)
        .id("\(viewModel.selectedSport.rawValue)-\(viewModel.teamNames.joined(separator: "|"))")
    }
}

// MARK: - Team Header View
// Team picker plus editable team-name field used where a full team header is needed.
struct TeamHeaderView: View {
    // Shared app state for team selection and team name updates.
    @ObservedObject var viewModel: LineupViewModel
    // Local editable team-name text owned by the parent view.
    @Binding var editedTeamName: String

    // Saves team name changes on submit or button tap.
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Team selector at the top of the header.
            TeamPickerView(viewModel: viewModel)

            // Editable team name field.
            TextField("Team name", text: $editedTeamName)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    viewModel.updateSelectedTeamName(editedTeamName)
                }

            // Explicit save button for users who do not submit from the keyboard.
            Button("Save Team Name") {
                viewModel.updateSelectedTeamName(editedTeamName)
            }
            .buttonStyle(.bordered)
        }
        // Refresh the edit field when switching between team slots.
        .onChange(of: viewModel.selectedTeamIndex) { _, _ in
            editedTeamName = viewModel.selectedTeamName
        }
    }
}
