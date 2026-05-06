// Created by Rich Morris on 5/5/26.
// Lineup Changer
// SettingsSupportViews.swift
//
//
//
// SettingsSupportViews.swift contains reusable UIKit bridge views used by Settings.
// These wrappers provide SwiftUI access to the iOS share sheet and document picker
// for import/export workflows.
import SwiftUI
import UIKit
import UniformTypeIdentifiers

// MARK: - Activity View
// SwiftUI wrapper around UIActivityViewController.
// Used for sharing PDFs, exports, and other generated files.
struct ActivityView: UIViewControllerRepresentable {
    // Items passed into the native iOS share sheet.
    let activityItems: [Any]

    // MARK: - UIViewControllerRepresentable
    // Creates the native iOS activity/share sheet.
    func makeUIViewController(context: Context) -> UIActivityViewController {
        // applicationActivities remains nil so the system chooses available actions.
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    // No live updates are required after the activity view is presented.
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}

// MARK: - Import Document Picker
// SwiftUI wrapper around UIDocumentPickerViewController.
// Used for importing JSON, CSV, and other supported app documents.
struct ImportDocumentPicker: UIViewControllerRepresentable {
    // Allowed document types that may be selected.
    let contentTypes: [UTType]
    // Called when the user successfully selects a document.
    let onPick: (URL) -> Void
    // Called when the picker is dismissed without selecting a file.
    let onCancel: () -> Void

    // MARK: - UIViewControllerRepresentable
    // Creates and configures the native iOS document picker.
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Files are imported as copies so the app can safely access them later.
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes, asCopy: true)
        // Coordinator bridges UIKit delegate callbacks back into SwiftUI closures.
        picker.delegate = context.coordinator
        // Import workflows currently support one file at a time.
        picker.allowsMultipleSelection = false
        return picker
    }

    // No live updates are required after the document picker is presented.
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) { }

    // Creates the delegate coordinator used by UIDocumentPickerViewController.
    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick, onCancel: onCancel)
    }

    // MARK: - Coordinator
    // Handles document picker delegate callbacks.
    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        // Closures forwarded from the SwiftUI wrapper.
        let onPick: (URL) -> Void
        let onCancel: () -> Void

        // Store callback closures for later delegate events.
        init(onPick: @escaping (URL) -> Void, onCancel: @escaping () -> Void) {
            self.onPick = onPick
            self.onCancel = onCancel
        }

        // Called after the user selects one or more documents.
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            // Defensive fallback in case the picker returns an empty URL array.
            guard let url = urls.first else {
                onCancel()
                return
            }
            // Forward the selected file URL to the SwiftUI caller.
            onPick(url)
        }

        // Called when the user dismisses the picker without choosing a document.
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // Forward the cancellation event back to SwiftUI.
            onCancel()
        }
    }
}
