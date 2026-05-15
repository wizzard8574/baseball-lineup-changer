import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: LineupViewModel
    @State var selectedTab: MainTab = .field

    var body: some View {
        mainTabView
    }
}

#Preview {
    RootView()
}
