// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BaseballFieldLineupView.swift
//
//
//
// BaseballFieldLineupView positions player markers over the baseball/softball field image.
import SwiftUI

// MARK: - Baseball Field Lineup Overlay
// Interactive overlay that positions a marker for every baseball/softball field position.
// Marker coordinates are proportional to the available field size so the overlay scales
// with the field image.
struct BaseballFieldLineupView: View {
    // Current field assignments keyed by defensive position.
    let lineup: [FieldPosition: Player]
    // Controls whether player position ratings are displayed on markers.
    let showRatings: Bool
    // Controls compact versus full marker name formatting.
    let showFullNameAndNumber: Bool
    // Optional tap handler used by parent screens to open assignment controls.
    var onPositionTap: ((FieldPosition) -> Void)? = nil
    // Turns on the marker entrance animation after the overlay appears.
    @State var hasAppeared = false
    // Tracks the last tapped marker so it can be highlighted above the others.
    @State var selectedPosition: FieldPosition?

    // Places all position markers over the field using proportional coordinates.
    var body: some View {
        GeometryReader { geometry in
            // Current overlay size used to convert proportional marker coordinates to points.
            let width = geometry.size.width
            let height = geometry.size.height

            ZStack {
                // Outfield positions.
                positionMarker(.centerField, at: CGPoint(x: width * 0.47, y: height * 0.13), fieldSize: geometry.size)
                positionMarker(.leftField, at: CGPoint(x: width * 0.17, y: height * 0.29), fieldSize: geometry.size)
                positionMarker(.rightField, at: CGPoint(x: width * 0.77, y: height * 0.29), fieldSize: geometry.size)
                // Middle infield positions.
                positionMarker(.shortstop, at: CGPoint(x: width * 0.35, y: height * 0.47), fieldSize: geometry.size)
                positionMarker(.secondBase, at: CGPoint(x: width * 0.60, y: height * 0.47), fieldSize: geometry.size)
                // Corner infield positions.
                positionMarker(.thirdBase, at: CGPoint(x: width * 0.28, y: height * 0.64), fieldSize: geometry.size)
                positionMarker(.firstBase, at: CGPoint(x: width * 0.67, y: height * 0.64), fieldSize: geometry.size)
                // Battery positions are anchored lower on the field preview.
                positionMarker(.pitcher, at: CGPoint(x: width * 0.12, y: height * 0.82), fieldSize: geometry.size)
                positionMarker(.catcher, at: CGPoint(x: width * 0.76, y: height * 0.82), fieldSize: geometry.size)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .animation(.easeInOut(duration: 0.25), value: lineup)
            .onAppear {
                // Animate markers into place after the field overlay appears.
                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                    hasAppeared = true
                }
            }
        }
    }
}
