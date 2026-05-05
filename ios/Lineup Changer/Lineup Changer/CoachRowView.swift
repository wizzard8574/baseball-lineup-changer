//
//  CoachRowView.swift
//  Lineup Changer
//
//  Created by Rich Morris on 5/4/26.
//


//
//  CoachRowView.swift
//  Lineup Changer
//
//  Created by Rich Morris on 5/4/26.
//

import SwiftUI

struct CoachRowView: View {
    let coach: Coach

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(coach.name)
                    .font(.headline)

                if !coach.role.isEmpty {
                    Text("- \(coach.role)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !coach.number.isEmpty {
                Text("#\(coach.number)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            PhoneContactMenu(number: coach.cell)
                .font(.caption)
        }
    }
}
