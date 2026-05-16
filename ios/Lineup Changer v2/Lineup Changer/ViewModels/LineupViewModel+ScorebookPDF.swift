// Created by Rich Morris on 5/5/26.
// Lineup Changer
// LineupViewModel+ScorebookPDF.swift
//
//
//
// Scorebook PDF export entry point.
import Foundation
import UIKit

// MARK: - Scorebook PDF Export
extension LineupViewModel {
    // MARK: - PDF Creation
    // Creates a two-page scorebook PDF and returns the temporary file URL.
    func createScorebookPDF() throws -> URL {
        // Standard US Letter PDF page size in points.
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        // Write the export with the team, sport, and file type in the name.
        let outputURL = sharedFileURL(fileDescription: "Scorebook", fileExtension: "pdf")
        // UIGraphicsPDFRenderer provides the drawing context for the generated PDF pages.
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        try renderer.writePDF(to: outputURL) { context in
            // First page includes the current lineup data.
            context.beginPage()
            // Common text styles used throughout the PDF.
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 18),
                .foregroundColor: UIColor.black
            ]
            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 8),
                .foregroundColor: UIColor.black
            ]
            let cellAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 7),
                .foregroundColor: UIColor.black
            ]
            // Draw the title and all scorebook sections on page one.
            let title = "Lineup Changer Scorebook"
            title.draw(
                in: CGRect(x: 0, y: 18, width: pageRect.width, height: 24),
                withAttributes: titleAttributes.centered
            )
            drawScorebookInfoHeader(in: pageRect)
            drawScorebookLineupTable(
                in: pageRect,
                headerAttributes: headerAttributes,
                cellAttributes: cellAttributes
            )
            drawScorebookTotalsSection(in: pageRect, headerAttributes: headerAttributes)
            drawScorebookPitchingSection(in: pageRect, headerAttributes: headerAttributes)
            // Second page is a blank scorebook page without pre-filled player rows.
            context.beginPage()
            title.draw(
                in: CGRect(x: 0, y: 18, width: pageRect.width, height: 24),
                withAttributes: titleAttributes.centered
            )
            drawScorebookInfoHeader(in: pageRect)
            drawScorebookLineupTable(
                in: pageRect,
                headerAttributes: headerAttributes,
                cellAttributes: cellAttributes,
                includePlayers: false
            )
            drawScorebookTotalsSection(in: pageRect, headerAttributes: headerAttributes)
            drawScorebookPitchingSection(in: pageRect, headerAttributes: headerAttributes)
        }
        // Return the generated file so the caller can share it.
        return outputURL
    }
}
