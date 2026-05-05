//
//  TeamPickerBar.swift
//  Lineup Changer
//
//  Created by Rich Morris on 5/4/26.
//


//
//  TeamPickerBar.swift
//  Lineup Changer
//
//  Created by Rich Morris on 5/4/26.
//

import SwiftUI

struct TeamPickerBar: View {
    @ObservedObject var viewModel: LineupViewModel
    let onTeamChange: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TeamPickerView(viewModel: viewModel)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(Color(uiColor: .systemBackground).opacity(0.92), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                .padding(.horizontal, 32)
                .onChange(of: viewModel.selectedTeamIndex) { _, _ in
                    onTeamChange()
                }
        }
    }
}
