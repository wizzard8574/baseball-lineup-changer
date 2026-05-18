import SwiftUI

struct SettingsView: View {
    @Binding var showCallsTab: Bool
    @Binding var showPlaysTab: Bool
    @Binding var showMessageTab: Bool

    var body: some View {
        NavigationStack {
            List {
                Section("Tabs") {
                    Toggle("Show Calls", isOn: $showCallsTab)
                    Toggle("Show Common", isOn: $showMessageTab)
                    Toggle("Show Plays", isOn: $showPlaysTab)
                }
                .listRowBackground(Color.white.opacity(0.12))
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .navigationTitle("Settings")
            .appScreenBackground()
        }
    }
}
