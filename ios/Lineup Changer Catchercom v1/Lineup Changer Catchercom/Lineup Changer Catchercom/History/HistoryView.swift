//
//  HistoryView.swift
//  Lineup Changer Catchercom
//
//  Created by Rich Morris on 5/18/26.
//

import SwiftUI

struct HistoryView: View {
    // MARK: - Dependencies

    @ObservedObject var audio: CatcherAudioManager

    // MARK: - State

    @State private var exportFile: PitchHistoryExportFile?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                Section(header: ListSectionHeader(title: "History")) {
                    if audio.history.isEmpty {
                        Text("No calls yet")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(audio.history) { item in
                            HistoryRow(item: item)
                        }
                    }
                }
                .catcherListRowBackground()
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .navigationTitle("History")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        exportFile = PitchHistoryCSVExporter.makeFile(from: audio.history)
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .disabled(audio.history.isEmpty)

                    Button("Clear") {
                        audio.clearHistory()
                    }
                    .disabled(audio.history.isEmpty)
                }
            }
            .sheet(item: $exportFile) { file in
                ShareSheet(activityItems: [file.url])
            }
            .appScreenBackground()
        }
    }
}

// MARK: - History Row

private struct HistoryRow: View {
    // MARK: Properties

    let item: CallHistoryItem

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .font(.headline)

            Text(item.sentAt, format: .dateTime.hour().minute().second())
                .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}
