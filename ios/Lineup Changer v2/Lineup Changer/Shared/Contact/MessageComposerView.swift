// Created by Rich Morris on 5/5/26.
// Lineup Changer
// MessageComposerView.swift
//
//
//
// SwiftUI wrapper around MFMessageComposeViewController.
// This view presents the native iOS text-message composer so coaches can quickly
// contact players or other coaches without leaving the app.
import SwiftUI
import MessageUI


// MARK: - Message Composer View
// Bridges UIKit's message composer into SwiftUI.
struct MessageComposerView: UIViewControllerRepresentable {
    // Phone numbers that will receive the composed text message.
    var recipients: [String]
    // Default message text inserted into the composer.
    var body: String

    // SwiftUI dismissal action used after the message composer closes.
    @Environment(\.dismiss) private var dismiss

    // MARK: - UIViewControllerRepresentable
    // Creates and configures the UIKit message composer.
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        // Configure recipients, initial body text, and the delegate callback bridge.
        let controller = MFMessageComposeViewController()
        controller.recipients = recipients
        controller.body = body
        controller.messageComposeDelegate = context.coordinator
        return controller
    }

    // No live updates are needed once the message composer is presented.
    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

    // Creates the coordinator that receives UIKit delegate callbacks.
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator
    // Handles UIKit message-composer delegate events.
    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        // Reference back to the SwiftUI wrapper view.
        var parent: MessageComposerView

        // Store the parent wrapper so dismissal can be forwarded into SwiftUI.
        init(_ parent: MessageComposerView) {
            self.parent = parent
        }

        // Called when the user sends, cancels, or fails to send the message.
        func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                          didFinishWith result: MessageComposeResult) {
            // Close the UIKit controller first, then dismiss the SwiftUI presentation.
            controller.dismiss(animated: true)
            parent.dismiss()
        }
    }
}
