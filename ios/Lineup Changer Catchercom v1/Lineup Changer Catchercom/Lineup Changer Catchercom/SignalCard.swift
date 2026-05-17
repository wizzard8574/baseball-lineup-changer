import SwiftUI

struct SignalCard<Content: View>: View {
    let content: Content
    let onDelete: () -> Void
    let dragID: String

    init(
        dragID: String,
        @ViewBuilder content: () -> Content,
        onDelete: @escaping () -> Void
    ) {
        self.content = content()
        self.onDelete = onDelete
        self.dragID = dragID
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            content
                .padding(10)
                .padding(.top, 18)
                .frame(maxWidth: .infinity)

            HStack(spacing: 10) {
                Image(systemName: "line.3.horizontal")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(.regularMaterial)
                    )
                    .contentShape(Rectangle())
                    .draggable(dragID) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(.regularMaterial)
                            )
                    }
                    .accessibilityLabel("Drag to reorder")

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash.circle.fill")
                        .font(.body)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete")
            }
            .padding(5)
        }
        .frame(maxWidth: .infinity)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.secondary.opacity(0.35), lineWidth: 1)
        )
        .shadow(radius: 2)
    }
}
