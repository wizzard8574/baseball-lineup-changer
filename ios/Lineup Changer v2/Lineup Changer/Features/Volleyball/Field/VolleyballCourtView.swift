// Created by Rich Morris on 5/7/26.
// Lineup Changer
// VolleyballCourtView.swift
//
//
//
// VolleyballCourtView.swift will contain the volleyball court assignment workflow.
import SwiftUI

// MARK: - Volleyball Court View
struct VolleyballCourtView: View {
    @ObservedObject var viewModel: LineupViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                AppSportsBackground()

                VStack(spacing: 18) {
                    Image("Volleyball_Court_View")
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    Text("Volleyball court and lineup features will be added here.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 10) {
                        Image(systemName: "volleyball.fill")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.45), radius: 2, x: 0, y: 1)

                        Text("Court")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.25), in: Capsule())
                }
            }
        }
    }
}
