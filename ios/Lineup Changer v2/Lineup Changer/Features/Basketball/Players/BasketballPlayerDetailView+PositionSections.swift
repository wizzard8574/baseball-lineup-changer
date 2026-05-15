import SwiftUI

extension BasketballPlayerDetailView {
    var basketballAddPositionSection: some View {
        Section("Add or Update Position") {
            if availableBasketballPositions.isEmpty {
                Text("All positions already assigned.")
                    .foregroundStyle(.secondary)
            } else {
                Picker("Position", selection: $selectedBasketballPosition) {
                    ForEach(availableBasketballPositions) { position in
                        Text(position.rawValue).tag(position)
                    }
                }

                Picker("Rating", selection: $selectedBasketballRating) {
                    ForEach(1...5, id: \.self) { rating in
                        Text("\(rating)").tag(rating)
                    }
                }

                Button("Save Position") {
                    viewModel.setBasketballRating(
                        playerID: player.id,
                        position: selectedBasketballPosition,
                        rating: selectedBasketballRating
                    )
                    selectFirstAvailableBasketballPosition()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }

    var basketballCurrentPositionsSection: some View {
        Section("Current Positions") {
            if let currentPlayer, currentPlayer.basketballPositionRatings.isEmpty {
                Text("No positions added yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(BasketballPosition.allCases) { position in
                    if let rating = currentPlayer?.basketballPositionRatings[position] {
                        basketballCurrentPositionRow(position: position, rating: rating)
                    }
                }
            }
        }
    }

    private func basketballCurrentPositionRow(position: BasketballPosition, rating: Int) -> some View {
        HStack {
            Text(position.rawValue)
                .fontWeight(.semibold)

            Spacer()

            Picker("Rating", selection: Binding(
                get: { rating },
                set: { newRating in
                    viewModel.setBasketballRating(playerID: player.id, position: position, rating: newRating)
                }
            )) {
                ForEach(1...5, id: \.self) { rating in
                    Text("\(rating)").tag(rating)
                }
            }
            .pickerStyle(.segmented)
        }
        .swipeActions {
            Button("Remove", role: .destructive) {
                viewModel.removeBasketballPosition(playerID: player.id, position: position)
                selectFirstAvailableBasketballPosition()
            }
        }
    }

    var basketballRatingScaleSection: some View {
        Section("Scale") {
            Text("1 = High, 5 = Low. A player is only considered for positions listed here.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
