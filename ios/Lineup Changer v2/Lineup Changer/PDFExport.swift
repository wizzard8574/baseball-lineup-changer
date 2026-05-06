// Created by Rich Morris on 5/5/26.
// Lineup Changer
// PDFExport.swift
//
//
//
// PDFExport.swift contains lineup-grid PDF export support.
// This extension renders a landscape PDF showing each active/guest player and
// their assigned position for innings 1 through 9.
import Foundation
import SwiftUI
import UIKit

// MARK: - Lineup Grid PDF Export

// LineupViewModel owns the lineup state, so PDF export lives here as a focused extension.
extension LineupViewModel {
    // MARK: - PDF Creation
    // Creates a landscape lineup-grid PDF and returns the temporary file URL.
    func createLineupGridPDF() throws -> URL {
        // Capture the visible inning before generating the PDF.
        saveCurrentInningState()

        // Landscape US Letter page layout constants.
        let pageWidth: CGFloat = 792
        let pageHeight: CGFloat = 612
        let margin: CGFloat = 36
        let titleHeight: CGFloat = 42
        let headerHeight: CGFloat = 28
        let rowHeight: CGFloat = 26
        let orderColumnWidth: CGFloat = 42
        let nameColumnWidth: CGFloat = 190
        // Split remaining table width evenly across nine inning columns.
        let inningColumnWidth = (pageWidth - (margin * 2) - orderColumnWidth - nameColumnWidth) / 9

        // Export players in batting-order order, excluding injured/unavailable players.
        let orderedPlayers = battingOrderIDs
            .compactMap { player(for: $0) }
            .filter { $0.status == .active || $0.status == .guest }

        // UIGraphicsPDFRenderer provides the drawing context for the PDF.
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        // Save the generated PDF in the temporary directory using a filesystem-safe team name.
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(safeFileName(selectedTeamName))-Lineup.pdf")

        try renderer.writePDF(to: url) { context in
            // Tracks which player row should be drawn next across one or more pages.
            var playerIndex = 0

            // Add pages until every ordered player has been written.
            repeat {
                // Start a new PDF page.
                context.beginPage()

                // Draw title and subtitle at the top of the page.
                drawPDFText(
                    selectedTeamName,
                    in: CGRect(x: margin, y: 22, width: pageWidth - margin * 2, height: 26),
                    font: .boldSystemFont(ofSize: 20),
                    alignment: .center
                )

                drawPDFText(
                    "Lineup Grid",
                    in: CGRect(x: margin, y: 48, width: pageWidth - margin * 2, height: 18),
                    font: .systemFont(ofSize: 12),
                    alignment: .center
                )

                // Start table drawing below the title area.
                var y = margin + titleHeight
                drawPDFCell("#", x: margin, y: y, width: orderColumnWidth, height: headerHeight, isHeader: true)
                drawPDFCell("Player", x: margin + orderColumnWidth, y: y, width: nameColumnWidth, height: headerHeight, isHeader: true)

                // Header cells for inning columns.
                for inning in 1...9 {
                    let x = margin + orderColumnWidth + nameColumnWidth + CGFloat(inning - 1) * inningColumnWidth
                    drawPDFCell("\(inning)", x: x, y: y, width: inningColumnWidth, height: headerHeight, isHeader: true)
                }

                y += headerHeight

                // Draw as many player rows as fit on this page.
                while playerIndex < orderedPlayers.count && y + rowHeight <= pageHeight - margin {
                    // Current player being written to the lineup grid.
                    let player = orderedPlayers[playerIndex]
                    drawPDFCell("\(playerIndex + 1)", x: margin, y: y, width: orderColumnWidth, height: rowHeight)
                    drawPDFCell(displayLabel(for: player), x: margin + orderColumnWidth, y: y, width: nameColumnWidth, height: rowHeight, alignment: .left)

                    // Fill each inning cell with the player's assignment or Bench.
                    for inning in 1...9 {
                        let inningLineup = inningLineups[inning] ?? [:]
                        let positionText = positionForPlayer(player, in: inningLineup)
                        let x = margin + orderColumnWidth + nameColumnWidth + CGFloat(inning - 1) * inningColumnWidth
                        drawPDFCell(positionText, x: x, y: y, width: inningColumnWidth, height: rowHeight)
                    }

                    y += rowHeight
                    playerIndex += 1
                }
            } while playerIndex < orderedPlayers.count
        }

        // Return the generated PDF file URL for sharing.
        return url
    }

    // MARK: - Position Lookup
    // Returns the player's defensive position in a lineup, or Bench when unassigned.
    private func positionForPlayer(_ player: Player, in lineup: [FieldPosition: Player]) -> String {
        // Search by player ID because lineup stores full Player values.
        if let position = lineup.first(where: { $0.value.id == player.id })?.key {
            return position.rawValue
        }
        // Players without a field assignment are shown as Bench.
        return "Bench"
    }

    // MARK: - PDF Drawing Helpers
    // Draws one bordered table cell with optional header styling.
    private func drawPDFCell(
        _ text: String,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        height: CGFloat,
        isHeader: Bool = false,
        alignment: NSTextAlignment = .center
    ) {
        // Build the cell rectangle from the supplied table coordinates.
        let rect = CGRect(x: x, y: y, width: width, height: height)
        // Draw the cell border.
        UIColor.black.setStroke()
        UIBezierPath(rect: rect).stroke()

        // Header cells receive a light gray fill behind the text.
        if isHeader {
            UIColor.systemGray5.setFill()
            UIBezierPath(rect: rect).fill()
            UIColor.black.setStroke()
            UIBezierPath(rect: rect).stroke()
        }

        // Draw the cell text inset slightly from the border.
        drawPDFText(
            text,
            in: rect.insetBy(dx: 3, dy: 5),
            font: isHeader ? .boldSystemFont(ofSize: 10) : .systemFont(ofSize: 9),
            alignment: alignment
        )
    }

    // Draws text inside a PDF rectangle using the requested font and alignment.
    private func drawPDFText(
        _ text: String,
        in rect: CGRect,
        font: UIFont,
        alignment: NSTextAlignment
    ) {
        // Paragraph style controls alignment and truncation.
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.lineBreakMode = .byTruncatingTail

        // UIKit text attributes used by NSString drawing.
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black,
            .paragraphStyle: paragraphStyle
        ]

        // Render the text into the current PDF graphics context.
        text.draw(in: rect, withAttributes: attributes)
    }

    // MARK: - File Name Helpers
    // Replaces characters that are invalid in file names.
    private func safeFileName(_ name: String) -> String {
        // Characters not allowed or problematic in generated file names.
        let invalidCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        return name.components(separatedBy: invalidCharacters).joined(separator: "-")
    }
}
