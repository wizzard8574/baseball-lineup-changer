// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BaseballPlayerDetailView+ScreenChrome.swift
//
//
//
import SwiftUI

// MARK: - Baseball Player Detail Screen Chrome
extension BaseballPlayerDetailView {
    var playerDetailScreen: some View {
        ZStack {
            AppSportsBackground()

            Form {
                playerFormSections
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            playerDetailToolbar
        }
        .sheet(isPresented: $isShowingMessageComposer) {
            MessageComposerView(recipients: [phoneDigits(editedCellNumber)], body: "")
        }
        .alert("Unable to Text", isPresented: messageAlertBinding) {
            Button("OK", role: .cancel) { messageAlertText = nil }
        } message: {
            Text(messageAlertText ?? "")
        }
        .alert("Duplicate Player Number", isPresented: duplicateNumberAlertBinding) {
            Button("OK", role: .cancel) { duplicateNumberAlertText = nil }
        } message: {
            Text(duplicateNumberAlertText ?? "")
        }
        .onAppear(perform: loadPlayerInfo)
    }

    @ToolbarContentBuilder
    private var playerDetailToolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            playerDetailTitle
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

    private var messageAlertBinding: Binding<Bool> {
        Binding(
            get: { messageAlertText != nil },
            set: { if !$0 { messageAlertText = nil } }
        )
    }

    private var duplicateNumberAlertBinding: Binding<Bool> {
        Binding(
            get: { duplicateNumberAlertText != nil },
            set: { if !$0 { duplicateNumberAlertText = nil } }
        )
    }
}
