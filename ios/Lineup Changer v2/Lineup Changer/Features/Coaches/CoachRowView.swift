// Created by Rich Morris on 5/5/26.
// Lineup Changer
// CoachRowView.swift
//
//
//
import SwiftUI

// MARK: - Coach Row View
// Displays a single coach in a list-style row.
// The row shows the coach name, optional role, optional number, and a reusable
// phone contact menu for calling/texting the saved cell number.
struct CoachRowView: View {
    // Coach model rendered by this row.
    let coach: Coach

    // Main row layout.
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Name and role are shown on the same line so the role reads as a subtitle.
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(coach.name)
                    .font(.headline)

                if !coach.role.isEmpty {
                    Text("- \(coach.role)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Only show the coach number when one has been entered.
            if !coach.number.isEmpty {
                Text("#\(coach.number)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Shared call/text menu for the coach's cell number.
            PhoneContactMenu(number: coach.cell)
                .font(.caption)
        }
    }
}
