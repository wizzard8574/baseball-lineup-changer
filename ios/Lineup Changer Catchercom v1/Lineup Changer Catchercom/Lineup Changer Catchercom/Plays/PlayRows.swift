//
//  PlayRows.swift
//  Lineup Changer Catchercom
//
//  Created by Rich Morris on 5/18/26.
//

import SwiftUI

// MARK: - Play Row

struct PlayCallRow: View {
    // MARK: - Properties

    let play: PlayCallItem
    let onSend: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(play.title)
                    .font(.headline)

                Text(play.numbers.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Send") {
                onSend()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
// MARK: - Category Row

struct PlayCategoryRow: View {
    // MARK: Properties

    let category: PlayCategory

    // MARK: Body

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "folder.fill")
                .foregroundStyle(.yellow)

            VStack(alignment: .leading, spacing: 2) {
                Text(category.title)
                    .font(.headline.weight(.bold))

                Text("\(category.plays.count) \(category.plays.count == 1 ? "play" : "plays")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Empty States

struct EmptyPlaySetupRow: View {
    // MARK: Body

    var body: some View {
        Label("Add a category to start building plays", systemImage: "plus.circle")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
    }
}

struct EmptyPlayCategoryRow: View {
    // MARK: Body

    var body: some View {
        Text("No plays in this category")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
