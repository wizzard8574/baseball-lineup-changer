// Created by Rich Morris on 5/5/26.
// Lineup Changer
// AppSportsBackground.swift
//
//
//
// Reusable sports-themed background shared across app screens.
import SwiftUI

// MARK: - Shared Background
// Reusable sports-themed background made from gradients and blurred color circles.
struct AppSportsBackground: View {
    // Layered background used where the app needs a branded sports-style backdrop.
    var body: some View {
        ZStack {
            // Base diagonal gradient.
            LinearGradient(
                colors: [
                    Color.black.opacity(0.95),
                    Color.blue.opacity(0.38),
                    Color.yellow.opacity(0.30),
                    Color.black.opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Large blurred circles add soft blue/yellow lighting effects.
            Circle()
                .fill(Color.blue.opacity(0.32))
                .frame(width: 420, height: 420)
                .blur(radius: 80)
                .offset(x: -180, y: -260)

            Circle()
                .fill(Color.yellow.opacity(0.24))
                .frame(width: 420, height: 420)
                .blur(radius: 90)
                .offset(x: 190, y: -120)

            Circle()
                .fill(Color.blue.opacity(0.18))
                .frame(width: 360, height: 360)
                .blur(radius: 90)
                .offset(x: -150, y: 320)

            Circle()
                .fill(Color.yellow.opacity(0.18))
                .frame(width: 360, height: 360)
                .blur(radius: 90)
                .offset(x: 170, y: 360)

            // Light overlay adds depth and keeps the background from looking flat.
            LinearGradient(
                colors: [
                    Color.white.opacity(0.06),
                    Color.clear,
                    Color.white.opacity(0.04)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
}
