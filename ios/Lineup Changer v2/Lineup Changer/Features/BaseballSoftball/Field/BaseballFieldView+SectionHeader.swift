// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BaseballFieldView+SectionHeader.swift
//
//
//
import SwiftUI

// MARK: - Baseball / Softball Field Section Header
extension BaseballFieldView {
    // MARK: - Section Header Styling
    func fieldSectionHeader(_ title: String) -> some View {
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
