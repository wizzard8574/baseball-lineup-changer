import SwiftUI

struct InitialSportSelectionView: View {
    @ObservedObject var viewModel: LineupViewModel
    let onSportSelected: () -> Void
    @State var selectedSport: SportType?

    var body: some View {
        initialSportSelectionScreen
    }
}
