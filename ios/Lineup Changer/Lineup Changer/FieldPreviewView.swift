//
//  FieldPreviewView.swift
//  Lineup Changer
//
//  Created by Rich Morris on 5/4/26.
//

import SwiftUI

struct FieldPreviewView: View {
    let lineup: [FieldPosition: Player]
    let showRatings: Bool
    let showFullNameAndNumber: Bool
    let onPositionTap: (FieldPosition) -> Void

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)

            ZStack {
                Image("baseball_field_clean")
                    .resizable()
                    .scaledToFit()
                    .frame(width: side, height: side)

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
