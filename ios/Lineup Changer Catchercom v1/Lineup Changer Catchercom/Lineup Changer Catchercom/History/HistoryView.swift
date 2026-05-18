import SwiftUI

struct HistoryView: View {
    @ObservedObject var audio: CatcherAudioManager

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
                Button("Clear") {
                    audio.clearHistory()
                }
                .disabled(audio.history.isEmpty)
            }
            .appScreenBackground()
        }
    }
}

private struct HistoryRow: View {
    let item: CallHistoryItem

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
