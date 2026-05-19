import SwiftUI

struct ListSectionHeader: View {
    // MARK: - Properties

    let title: String

    // MARK: - Body

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

struct SpokenMessageText: View {
    // MARK: - Properties

    let message: String

    // MARK: - Body

    var body: some View {
        Text(message)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
    }
}

extension View {
    // MARK: - List Styling

    func catcherListRowBackground() -> some View {
        listRowBackground(Color.white.opacity(0.12))
    }
}
