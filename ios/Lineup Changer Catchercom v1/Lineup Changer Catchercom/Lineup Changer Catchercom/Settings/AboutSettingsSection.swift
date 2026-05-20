// Created by Rich Morris on 5/5/26.
// Lineup Changer
// AboutSettingsSection.swift
//
//
//
// AboutSettingsSection contains version, app summary, and legal information.
import SwiftUI

// MARK: - About Settings Section
// App version, usage summary, and legal information.
struct AboutSettingsSection: View {
    var body: some View {
        Section(header: SettingsSectionHeader(title: "About")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Version \(appVersion) (Build \(buildNumber))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Divider()

                Text("Legal")
                    .font(.headline)

                Text("© 2026 Richard C. Morris Jr. All rights reserved.")
                    .font(.footnote)

                Text("This application and its contents are proprietary. Unauthorized copying, distribution, modification, or reverse engineering is strictly prohibited.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Text("This app is provided \"as is\" without warranty of any kind, express or implied, including but not limited to fitness for a particular purpose.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // Reads the marketing version from the app bundle.
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
    }

    // Reads the build number from the app bundle.
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
    }
}
