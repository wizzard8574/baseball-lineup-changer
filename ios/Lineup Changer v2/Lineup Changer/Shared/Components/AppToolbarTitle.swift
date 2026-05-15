// Created by Rich Morris on 5/5/26.
// Lineup Changer
// AppToolBarTitle.swift
//
//
//
import SwiftUI

struct AppToolbarTitle: View {
    let title: String
    let systemImage: String
    var isCompact = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(isCompact ? .headline.weight(.bold) : .title2.weight(.bold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.45), radius: 2, x: 0, y: 1)

            Text(title)
                .font(isCompact ? .headline.weight(.bold) : .title.bold())
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(isCompact ? 0.65 : 0.8)
                .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, isCompact ? 7 : 6)
        .background(.black.opacity(0.25), in: Capsule())
    }
}
