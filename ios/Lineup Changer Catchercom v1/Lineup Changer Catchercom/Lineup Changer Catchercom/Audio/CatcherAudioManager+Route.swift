//

import AVFoundation
import Foundation

extension CatcherAudioManager {
    // MARK: - Output Route

    @objc func audioRouteDidChange() {
        Task { @MainActor in
            updateOutputDeviceName()
        }
    }

    func updateOutputDeviceName() {
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs

        guard let output = outputs.first else {
            outputDeviceName = "No output device"
            return
        }

        outputDeviceName = output.portName
    }
}
//  CatcherAudioManager+Route.swift
//  Lineup Changer Catchercom
//
//  Created by Rich Morris on 5/19/26.
//
