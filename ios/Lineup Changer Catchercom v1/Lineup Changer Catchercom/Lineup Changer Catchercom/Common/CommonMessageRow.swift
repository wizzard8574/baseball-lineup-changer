import SwiftUI

// MARK: - Common Row

struct CommonMessageRow: View {
    // MARK: Properties

    let item: CommonMessageItem
    let onSend: () -> Void

    // MARK: Body

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)

                Text(item.location.title)
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
