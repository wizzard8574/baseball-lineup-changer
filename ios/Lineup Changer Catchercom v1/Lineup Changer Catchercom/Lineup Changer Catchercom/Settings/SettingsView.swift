import SwiftUI

struct SettingsView: View {
    // MARK: - Bindings

    @Binding var showCallsTab: Bool
    @Binding var showPlaysTab: Bool
    @Binding var showMessageTab: Bool
    @Binding var showHistoryTab: Bool

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                Section("Tabs") {
                    // Tab visibility is cosmetic only; turning a tab off does not clear its saved data.
                    Toggle("Show Calls", isOn: $showCallsTab)
                    Toggle("Show Common", isOn: $showMessageTab)
                    Toggle("Show Plays", isOn: $showPlaysTab)
                    Toggle("Show History", isOn: $showHistoryTab)
                }
                .listRowBackground(Color.white.opacity(0.12))

                AboutSettingsSection()
                    .listRowBackground(Color.white.opacity(0.12))
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .navigationTitle("Settings")
            .appScreenBackground()
        }
    }
}
