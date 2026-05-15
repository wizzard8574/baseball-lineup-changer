// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BaseballFieldView+InfoSections.swift
//
//
//
import SwiftUI

// MARK: - Info Sections
extension BaseballFieldView {
    var assignmentInfoSection: some View {
        Section(header: fieldSectionHeader("How assignment works")) {
            Text(viewModel.fallBallEnabled ? "Fall Ball generates all 9 innings at once and tries to share bench time evenly. Standard Fall Ball automatically uses a different pitcher each inning from players who have Pitcher listed on their profile, keeps catcher manual, then randomly assigns players only to positions listed on their profile. Youth mode randomly assigns all active players across every position, including pitcher and catcher." : "Each inning can have a different field lineup. When you set an inning, the app carries that lineup forward to later empty innings until you manually change or auto-fill those innings. Pitcher and catcher are selected manually. The app fills 1B, 2B, 3B, SS, LF, CF, and RF using the best available rating.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
