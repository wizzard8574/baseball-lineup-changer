//
//  SettingsView.swift
//  Lineup Changer
//
//  Created by Rich Morris on 5/1/26.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

// MARK: - Settings Tab



struct SettingsView: View {
    @ObservedObject var viewModel: LineupViewModel
    @State private var editedTeamName = ""
    @FocusState private var isTeamNameFocused: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Team - \(viewModel.selectedTeamName)") {
                    TeamPickerView(viewModel: viewModel)
                    TextField("Team name", text: $editedTeamName)
                        .textFieldStyle(.roundedBorder)
                        .focused($isTeamNameFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            viewModel.updateSelectedTeamName(editedTeamName)
                            isTeamNameFocused = false
                        }
                    Button("Save Team Name") {
                        viewModel.updateSelectedTeamName(editedTeamName)
                        isTeamNameFocused = false
                    }
                }
                
                Section("Sport - \(viewModel.selectedSport.rawValue)") {
                    Picker("Sport", selection: $viewModel.selectedSport) {
                        ForEach(SportType.allCases) { sport in
                            Image(systemName: iconName(for: sport))
                                .tag(sport)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Text("Current sport selection only. Field, lineup, player positions, and sport-specific rules will be updated in later phases.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                if viewModel.selectedSport == .baseballSoftball {
                    Section("Lineup Display") {
                        Toggle("Show ratings on field", isOn: $viewModel.showRatingsOnField)
                        Toggle("Show assigned lineup table", isOn: $viewModel.showAssignedLineupTable)
                        Toggle("Use first initial, last name, and number", isOn: Binding(
                            get: { !viewModel.showFullNameAndNumber },
                            set: { viewModel.showFullNameAndNumber = !$0 }
                        ))
                        Toggle("Show bench on field tab", isOn: $viewModel.showBenchOnField)
                    }
                    
                    Section("Batting Order") {
                        Toggle("Only show 9 batters and a DH", isOn: $viewModel.showOnlyNineBattersAndDH)
                        Toggle("Warn when No Steal P/C bats after No Steal runner", isOn: $viewModel.showSlowSpeedBattingWarnings)
                    }
                    
                    Section("Fall Ball") {
                        Toggle("Fall Ball", isOn: $viewModel.fallBallEnabled)
                        
                        if viewModel.fallBallEnabled {
                            Toggle("Youth", isOn: $viewModel.fallBallYouthEnabled)
                            
                            Text("Fall Ball generates all 9 fielding innings randomly while trying to keep bench time balanced. Youth mode removes manual pitcher/catcher selection and randomly assigns every active player across every position.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                
                
                SettingsDataSectionView(viewModel: viewModel)
                
                Section("About") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add players, give each player one or more positions, rate each position, manually set positions or auto-fill the rest of the field.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        
                        Divider()
                        
                        Text("Legal")
                            .font(.headline)
                        
                        Text("© 2026 Richard C. Morris Jr. All rights reserved.")
                            .font(.footnote)
                        
                        Text("This application and its contents are proprietary. Unauthorized copying, distribution, modification, or reverse engineering is strictly prohibited.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        
                        Text("This app is provided \"as is\" without warranty of any kind, express or implied, including but not limited to fitness for a particular purpose.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                editedTeamName = viewModel.selectedTeamName
            }
            .onChange(of: viewModel.selectedTeamIndex) { _, _ in
                editedTeamName = viewModel.selectedTeamName
                isTeamNameFocused = false
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        viewModel.updateSelectedTeamName(editedTeamName)
                        isTeamNameFocused = false
                    }
                }
            }
        }
    }
    private func iconName(for sport: SportType) -> String {
        switch sport {
        case .baseballSoftball: return "baseball"
        case .basketball: return "basketball"
        case .football: return "football"
        case .volleyball: return "volleyball"
        case .soccer: return "soccerball"
        }
    }
}
