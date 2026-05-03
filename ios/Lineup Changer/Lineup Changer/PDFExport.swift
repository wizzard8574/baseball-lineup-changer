import Foundation
import SwiftUI
import UIKit

// MARK: - PDF Export

extension LineupViewModel {
    func createLineupGridPDF() throws -> URL {
        saveCurrentInningState()

        let pageWidth: CGFloat = 792
        let pageHeight: CGFloat = 612
        let margin: CGFloat = 36
        let titleHeight: CGFloat = 42
        let headerHeight: CGFloat = 28
        let rowHeight: CGFloat = 26
        let orderColumnWidth: CGFloat = 42
        let nameColumnWidth: CGFloat = 190
        let inningColumnWidth = (pageWidth - (margin * 2) - orderColumnWidth - nameColumnWidth) / 9

        let orderedPlayers = battingOrderIDs
            .compactMap { player(for: $0) }
            .filter { $0.status == .active || $0.status == .guest }

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(safeFileName(selectedTeamName))-Lineup.pdf")

        try renderer.writePDF(to: url) { context in
            var playerIndex = 0

            repeat {
                context.beginPage()

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

                var y = margin + titleHeight
                drawPDFCell("#", x: margin, y: y, width: orderColumnWidth, height: headerHeight, isHeader: true)
                drawPDFCell("Player", x: margin + orderColumnWidth, y: y, width: nameColumnWidth, height: headerHeight, isHeader: true)

                for inning in 1...9 {
                    let x = margin + orderColumnWidth + nameColumnWidth + CGFloat(inning - 1) * inningColumnWidth
                    drawPDFCell("\(inning)", x: x, y: y, width: inningColumnWidth, height: headerHeight, isHeader: true)
                }

                y += headerHeight

                while playerIndex < orderedPlayers.count && y + rowHeight <= pageHeight - margin {
                    let player = orderedPlayers[playerIndex]
                    drawPDFCell("\(playerIndex + 1)", x: margin, y: y, width: orderColumnWidth, height: rowHeight)
                    drawPDFCell(displayLabel(for: player), x: margin + orderColumnWidth, y: y, width: nameColumnWidth, height: rowHeight, alignment: .left)

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

        return url
    }

    private func positionForPlayer(_ player: Player, in lineup: [FieldPosition: Player]) -> String {
        if let position = lineup.first(where: { $0.value.id == player.id })?.key {
            return position.rawValue
        }
        return "Bench"
    }

    private func drawPDFCell(
        _ text: String,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        height: CGFloat,
        isHeader: Bool = false,
        alignment: NSTextAlignment = .center
    ) {
        let rect = CGRect(x: x, y: y, width: width, height: height)
        UIColor.black.setStroke()
        UIBezierPath(rect: rect).stroke()

        if isHeader {
            UIColor.systemGray5.setFill()
            UIBezierPath(rect: rect).fill()
            UIColor.black.setStroke()
            UIBezierPath(rect: rect).stroke()
        }

        drawPDFText(
            text,
            in: rect.insetBy(dx: 3, dy: 5),
            font: isHeader ? .boldSystemFont(ofSize: 10) : .systemFont(ofSize: 9),
            alignment: alignment
        )
    }

    private func drawPDFText(
        _ text: String,
        in rect: CGRect,
        font: UIFont,
        alignment: NSTextAlignment
    ) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.lineBreakMode = .byTruncatingTail

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black,
            .paragraphStyle: paragraphStyle
        ]

        text.draw(in: rect, withAttributes: attributes)
    }

    private func safeFileName(_ name: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        return name.components(separatedBy: invalidCharacters).joined(separator: "-")
    }
}
