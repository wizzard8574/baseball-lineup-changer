// Created by Rich Morris on 5/5/26.
// Lineup Changer
// FieldPreviewView.swift
//
//
//
// FieldPreviewView displays the baseball field image with the current lineup layered on top.
import SwiftUI

// MARK: - Field Preview View
// Displays the baseball field image with the current lineup layered on top.
// The parent view provides the lineup data and handles taps on individual positions.
struct FieldPreviewView: View {
    // Maps each defensive field position to the player assigned there.
    let lineup: [FieldPosition: Player]
    // Controls whether position rating chips appear under assigned players.
    let showRatings: Bool
    // Controls whether markers show full names or compact first-name labels.
    let showFullNameAndNumber: Bool
    // Callback fired when the user taps a position marker.
    let onPositionTap: (FieldPosition) -> Void

    // Keeps the field preview square so the image and overlay markers stay aligned.
    var body: some View {
        GeometryReader { proxy in
            // Use the smaller dimension so the field remains a perfect square.
            let side = min(proxy.size.width, proxy.size.height)

            ZStack {
                // Static baseball field artwork.
                Image("baseball_field_clean")
                    .resizable()
                    .scaledToFit()
                    .frame(width: side, height: side)

                // Interactive lineup overlay positioned over the field image.
                BaseballFieldLineupView(
                    lineup: lineup,
                    showRatings: showRatings,
                    showFullNameAndNumber: showFullNameAndNumber,
                    onPositionTap: onPositionTap
                )
                .frame(width: side, height: side)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
