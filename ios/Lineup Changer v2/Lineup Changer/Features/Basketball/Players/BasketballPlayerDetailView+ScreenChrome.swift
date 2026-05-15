// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BasketballPlayerDetailView+ScreenChrome.swift
//
//
//
import SwiftUI

extension BasketballPlayerDetailView {
    var basketballPlayerDetailScreen: some View {
        ZStack {
            AppSportsBackground()

            Form {
                playerProfileSection
                notesSection
                gameChangerStatsSection
                basketballAddPositionSection
                basketballCurrentPositionsSection
                basketballRatingScaleSection
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                basketballPlayerDetailTitle
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    savePlayerInfo()
                    if duplicateNumberAlertText == nil {
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isPhoneNumberValidOrEmpty(editedCellNumber))
            }

            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    saveAndClearFocus()
                }
            }
        }
        .sheet(isPresented: $isShowingMessageComposer) {
            MessageComposerView(recipients: [phoneDigits(editedCellNumber)], body: "")
        }
        .alert("Unable to Text", isPresented: Binding(
            get: { messageAlertText != nil },
            set: { if !$0 { messageAlertText = nil } }
        )) {
            Button("OK", role: .cancel) { messageAlertText = nil }
        } message: {
            Text(messageAlertText ?? "")
        }
        .alert("Duplicate Player Number", isPresented: Binding(
            get: { duplicateNumberAlertText != nil },
            set: { if !$0 { duplicateNumberAlertText = nil } }
        )) {
            Button("OK", role: .cancel) { duplicateNumberAlertText = nil }
        } message: {
            Text(duplicateNumberAlertText ?? "")
        }
        .onAppear(perform: loadPlayerInfo)
    }
}
