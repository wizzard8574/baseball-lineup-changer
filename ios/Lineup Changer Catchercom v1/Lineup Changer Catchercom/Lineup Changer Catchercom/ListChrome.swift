import SwiftUI

struct ListSectionHeader: View {
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

extension View {
    func catcherListRowBackground() -> some View {
        listRowBackground(Color.white.opacity(0.12))
    }
}
