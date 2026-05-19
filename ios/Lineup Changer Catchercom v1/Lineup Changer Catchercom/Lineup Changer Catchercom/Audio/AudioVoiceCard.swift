//
//  AudioVoiceCard.swift
//  Lineup Changer Catchercom
//
//  Created by Rich Morris on 5/18/26.
//

import SwiftUI

struct AudioVoiceCard: View {
    // MARK: - Properties

    let statusTitle: String
    let statusIcon: String
    let audioState: String
    let outputDeviceName: String
    let canTransmit: Bool
    let startTransmit: () -> Void
    let stopTransmit: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Label(statusTitle, systemImage: statusIcon)
                    .font(.headline)

                Text(audioState)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Label(outputDeviceName, systemImage: "speaker.wave.2.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "mic.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(canTransmit ? .blue : .secondary)
                .opacity(canTransmit ? 1 : 0.35)
                .contentShape(Rectangle())
                // A zero-distance drag gives this button press-and-hold behavior instead of a normal tap.
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            guard canTransmit else { return }
                            startTransmit()
                        }
                        .onEnded { _ in
                            guard canTransmit else { return }
                            stopTransmit()
                        }
                )
                .accessibilityLabel("Hold to talk")
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
