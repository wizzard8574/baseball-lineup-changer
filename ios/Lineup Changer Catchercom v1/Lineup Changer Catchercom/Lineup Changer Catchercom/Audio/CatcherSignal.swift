//
//  CatcherSignal.swift
//  Lineup Changer Catchercom
//
//  Created by Rich Morris on 5/19/26.
//

// MARK: - Signal Model

struct CatcherSignal {
    let pitch: CatcherPitch
    let location: CatcherLocation

    var title: String {
        "\(pitch.title) \(location.title)"
    }
}
