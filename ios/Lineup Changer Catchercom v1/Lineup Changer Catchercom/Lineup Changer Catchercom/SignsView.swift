import SwiftUI

struct SignsView: View {
    @ObservedObject var audio: CatcherAudioManager
    @State private var signOrder: [NumberSignItem] = NumberSignItem.loadSavedOrder()
    @State private var newSignTitle = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    AudioVoiceCard(
                        statusTitle: statusTitle,
                        statusIcon: statusIcon,
                        audioState: audio.audioState,
                        canTransmit: true,
                        startTransmit: audio.startVoiceTransmit,
                        stopTransmit: audio.stopVoiceTransmit
                    )

                    addSignCard
                    signGridCard
                }
                .padding()
            }
            .background(Color.clear)
            .navigationTitle("Signs")
            .onChange(of: signOrder) { _, newValue in
                NumberSignItem.saveOrder(newValue)
            }
            .appScreenBackground()
        }
    }

    private var addSignCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Add")
                .font(.headline)

            HStack(spacing: 10) {
                TextField("New sign", text: $newSignTitle)
                    .textInputAutocapitalization(.words)
                    .textFieldStyle(.roundedBorder)

                Button("Add") {
                    addSign()
                }
                .buttonStyle(.borderedProminent)
                .disabled(newSignTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var signGridCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Send Sign")
                .font(.headline)

            LazyVGrid(columns: adaptiveColumns, spacing: 14) {
                ForEach(signOrder) { sign in
                    SignalCard(dragID: sign.id) {
                        NumberSignRow(item: sign, audio: audio)
                    } onDelete: {
                        deleteSign(sign)
                    }
                    .dropDestination(for: String.self) { draggedIDs, _ in
                        guard let draggedID = draggedIDs.first else { return false }
                        moveSign(withID: draggedID, before: sign.id)
                        return true
                    }
                }
            }

            Text(audio.lastMessage)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var statusTitle: String {
        "Audio Ready"
    }

    private var statusIcon: String {
        "speaker.wave.2.fill"
    }

    private var adaptiveColumns: [GridItem] {
        [
            GridItem(.adaptive(minimum: 300), spacing: 14)
        ]
    }

    private func addSign() {
        let trimmedTitle = newSignTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        signOrder.append(.custom(trimmedTitle))
        newSignTitle = ""
    }

    private func deleteSign(_ sign: NumberSignItem) {
        signOrder.removeAll { $0.id == sign.id }
    }

    private func moveSign(withID draggedID: String, before targetID: String) {
        guard draggedID != targetID,
              let fromIndex = signOrder.firstIndex(where: { $0.id == draggedID }),
              let toIndex = signOrder.firstIndex(where: { $0.id == targetID }) else {
            return
        }

        withAnimation(.snappy) {
            let movedSign = signOrder.remove(at: fromIndex)
            signOrder.insert(movedSign, at: toIndex)
        }
    }
}

private struct NumberSignItem: Identifiable, Equatable, Codable {
    let id: String
    let title: String
    let payloadValue: String

    private static let storageKey = "catchercom.signOrder"

    static var defaultOrder: [NumberSignItem] {
        [
            .builtIn(.one),
            .builtIn(.three),
            .builtIn(.two),
            .builtIn(.thirtyThree),
            .builtIn(.twentyTwo)
        ]
    }

    static func builtIn(_ sign: CatcherNumberSign) -> NumberSignItem {
        NumberSignItem(id: sign.rawValue, title: sign.title, payloadValue: sign.rawValue)
    }

    static func custom(_ title: String) -> NumberSignItem {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let payload = trimmedTitle
            .uppercased()
            .replacingOccurrences(of: " ", with: "_")

        return NumberSignItem(id: UUID().uuidString, title: trimmedTitle, payloadValue: payload)
    }

    static func loadSavedOrder() -> [NumberSignItem] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let savedOrder = try? JSONDecoder().decode([NumberSignItem].self, from: data) else {
            return defaultOrder
        }

        return savedOrder
    }

    static func saveOrder(_ order: [NumberSignItem]) {
        guard let data = try? JSONEncoder().encode(order) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

private struct NumberSignRow: View {
    let item: NumberSignItem
    @ObservedObject var audio: CatcherAudioManager

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

    private func locationButton(_ location: CatcherLocation, width: CGFloat = 52) -> some View {
        Button {
            audio.sendSignal(signTitle: item.title, signPayload: item.payloadValue, location: location)
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
