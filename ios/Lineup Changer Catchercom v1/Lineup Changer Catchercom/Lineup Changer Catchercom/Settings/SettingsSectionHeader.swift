// Created by Rich Morris on 5/5/26.
// Lineup Changer
// SettingsSectionHeader.swift
//
//
//
// SettingsSectionHeader provides the shared capsule header style for Settings sections.
import SwiftUI

// MARK: - Settings Section Header
// Shared styling helper for Settings section headers.
struct SettingsSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .textCase(nil)
            .shadow(color: .black.opacity(0.45), radius: 2, x: 0, y: 1)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.black.opacity(0.22), in: Capsule())
    }
}
