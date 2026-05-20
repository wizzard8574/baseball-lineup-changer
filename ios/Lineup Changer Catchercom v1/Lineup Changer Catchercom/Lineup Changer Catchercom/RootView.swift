//
//  RootView.swift
//  Lineup Changer Catchercom
//
//  Created by Rich Morris on 5/19/26.
//

import SwiftUI

struct RootView: View {
    // MARK: - State

    @State private var isShowingSplash = true

    // MARK: - Body

    var body: some View {
        ZStack {
            ContentView()
                .opacity(isShowingSplash ? 0 : 1)

            if isShowingSplash {
                SplashScreenView()
                    .transition(.opacity)
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(1.5))

            withAnimation(.easeOut(duration: 0.35)) {
                isShowingSplash = false
            }
        }
    }
}

#Preview {
    RootView()
}
