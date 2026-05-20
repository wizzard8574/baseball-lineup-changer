import SwiftUI

// MARK: - Pitch Row

struct PitchSignRow: View {
    // MARK: Properties

    let item: PitchCallItem
    @ObservedObject var audio: CatcherAudioManager
    let onSend: () -> Void

    // MARK: Body

    var body: some View {
        HStack(spacing: 12) {
            Text(item.title)
                .font(.headline)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(width: 86, alignment: .leading)

            VStack(spacing: 6) {
                locationButton(.up)

                HStack(spacing: 8) {
                    locationButton(.out)
                    locationButton(.middle, width: 58)
                    locationButton(.in)
                }

                locationButton(.down)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: Controls

    private func locationButton(_ location: CatcherLocation, width: CGFloat = 52) -> some View {
        Button {
            onSend()
            audio.sendSignal(pitchTitle: item.title, pitchPayload: item.payloadValue, location: location)
        } label: {
            Text(location.title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: width, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.blue)
                )
        }
        .buttonStyle(.plain)
        .opacity(audio.canSendSignal ? 1 : 0.85)
    }
}
