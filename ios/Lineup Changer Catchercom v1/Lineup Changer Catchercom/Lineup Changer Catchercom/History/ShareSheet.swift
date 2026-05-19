//
//  ShareSheet.swift
//  Lineup Changer Catchercom
//
//  Created by Rich Morris on 5/18/26.
//

import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    // MARK: - Properties

    let activityItems: [Any]

    // MARK: - UIViewControllerRepresentable

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
