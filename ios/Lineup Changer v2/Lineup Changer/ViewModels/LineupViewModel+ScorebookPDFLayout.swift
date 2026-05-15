// Created by Rich Morris on 5/5/26.
// Lineup Changer
// LineupViewModel+ScorebookPDFLayout.swift
//
//
//
// Scorebook PDF layout and drawing helpers.
import Foundation
import UIKit

// MARK: - Scorebook PDF Layout
extension LineupViewModel {
    // MARK: - Scorebook Header Drawing
    // Draws the top information box for team, date, opponent, scorer, start, and weather.
    func drawScorebookInfoHeader(in pageRect: CGRect) {
        // Layout constants for the three-column information grid.
        let left: CGFloat = 24
        let top: CGFloat = 52
        let width = pageRect.width - 48
        let rowHeight: CGFloat = 20
        let columnWidth = width / 3
        // Small bold labels keep the scorebook header compact.
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 7),
            .foregroundColor: UIColor.black
        ]
        let lineColor = UIColor.black
        lineColor.setStroke()
        // Draw three horizontal rows.
        for row in 0...2 {
            let y = top + CGFloat(row) * rowHeight
            UIBezierPath(rect: CGRect(x: left, y: y, width: width, height: rowHeight)).stroke()
        }
        // Draw vertical dividers to create three columns.
        for column in 1...2 {
            let x = left + CGFloat(column) * columnWidth
            UIBezierPath(rect: CGRect(x: x, y: top, width: 0.5, height: rowHeight * 3)).stroke()
        }
        // Team name is pre-filled; the rest are left blank for handwritten game details.
        let labels = [
            ("Team:", selectedTeamName),
            ("Date:", ""),
            ("Opponent:", ""),
            ("Scorer:", ""),
            ("Start:", ""),
            ("Weather:", "")
        ]
        // Place each label/value pair into the correct row and column.
        for index in 0..<labels.count {
            let row = index / 3
            let column = index % 3
            let x = left + CGFloat(column) * columnWidth + 6
            let y = top + CGFloat(row) * rowHeight + 5
            let text = labels[index].1.isEmpty ? labels[index].0 : "\(labels[index].0) \(labels[index].1)"
            text.draw(in: CGRect(x: x, y: y, width: columnWidth - 12, height: rowHeight), withAttributes: labelAttributes)
        }
    }

    // MARK: - Lineup Table Drawing
    // Draws the main scorebook lineup table with batter rows, inning boxes, and stat totals.
    func drawScorebookLineupTable(
        in pageRect: CGRect,
        headerAttributes: [NSAttributedString.Key: Any],
        cellAttributes: [NSAttributedString.Key: Any],
        includePlayers: Bool = true
    ) {
        // Layout constants for the lineup table columns and rows.
        let left: CGFloat = 24
        let top: CGFloat = 124
        let rowHeight: CGFloat = 34
        let numberWidth: CGFloat = 24
        let nameWidth: CGFloat = 112
        let posWidth: CGFloat = 28
        let inningWidth: CGFloat = 33
        let statWidth: CGFloat = 22
        let innings = 10
        let playerRows = 12
        let tableWidth = numberWidth + nameWidth + posWidth + CGFloat(innings) * inningWidth + statWidth * 4
        let headerHeight: CGFloat = 18
        // Draw the outer table border and all vertical/horizontal grid lines.
        UIColor.black.setStroke()
        UIBezierPath(rect: CGRect(x: left, y: top, width: tableWidth, height: headerHeight + CGFloat(playerRows) * rowHeight)).stroke()
        // Column boundaries for number, lineup name, position, inning boxes, and totals.
        let columnXs: [CGFloat] = [
            left,
            left + numberWidth,
            left + numberWidth + nameWidth,
            left + numberWidth + nameWidth + posWidth
        ]
        for x in columnXs.dropFirst() {
            UIBezierPath(rect: CGRect(x: x, y: top, width: 0.5, height: headerHeight + CGFloat(playerRows) * rowHeight)).stroke()
        }
        for inning in 0...innings {
            let x = left + numberWidth + nameWidth + posWidth + CGFloat(inning) * inningWidth
            UIBezierPath(rect: CGRect(x: x, y: top, width: 0.5, height: headerHeight + CGFloat(playerRows) * rowHeight)).stroke()
        }
        for stat in 0...4 {
            let x = left + numberWidth + nameWidth + posWidth + CGFloat(innings) * inningWidth + CGFloat(stat) * statWidth
            UIBezierPath(rect: CGRect(x: x, y: top, width: 0.5, height: headerHeight + CGFloat(playerRows) * rowHeight)).stroke()
        }
        for row in 0...playerRows {
            let y = top + headerHeight + CGFloat(row) * rowHeight
            UIBezierPath(rect: CGRect(x: left, y: y, width: tableWidth, height: 0.5)).stroke()
        }
        // Draw table header labels.
        "#".draw(in: CGRect(x: left, y: top + 5, width: numberWidth, height: headerHeight), withAttributes: headerAttributes.centered)
        "Line Up".draw(in: CGRect(x: left + numberWidth, y: top + 5, width: nameWidth, height: headerHeight), withAttributes: headerAttributes.centered)
        "Pos".draw(in: CGRect(x: left + numberWidth + nameWidth, y: top + 5, width: posWidth, height: headerHeight), withAttributes: headerAttributes.centered)
        for inning in 1...innings {
            let x = left + numberWidth + nameWidth + posWidth + CGFloat(inning - 1) * inningWidth
            "\(inning)".draw(in: CGRect(x: x, y: top + 5, width: inningWidth, height: headerHeight), withAttributes: headerAttributes.centered)
        }
        // Final columns are manual stat totals.
        let statHeaders = ["AB", "R", "H", "RBI"]
        for index in 0..<statHeaders.count {
            let x = left + numberWidth + nameWidth + posWidth + CGFloat(innings) * inningWidth + CGFloat(index) * statWidth
            statHeaders[index].draw(in: CGRect(x: x, y: top + 5, width: statWidth, height: headerHeight), withAttributes: headerAttributes.centered)
        }
        // Page one fills player rows from batting order; page two leaves rows blank.
        let orderedPlayers = includePlayers
            ? battingOrderIDs
                .compactMap { player(for: $0) }
                .filter { $0.status == .active }
            : []
        let maxRows = includePlayers ? min(orderedPlayers.count, playerRows) : playerRows
        // Draw player information and at-bat boxes for each scorebook row.
        for index in 0..<maxRows {
            let y = top + headerHeight + CGFloat(index) * rowHeight
            // Player text is skipped on blank scorebook pages.
            if includePlayers {
                let player = orderedPlayers[index]
                "\(index + 1)".draw(in: CGRect(x: left, y: y + 10, width: numberWidth, height: rowHeight), withAttributes: cellAttributes.centered)
                scorebookLineupName(for: player).draw(
                    in: CGRect(x: left + numberWidth + 4, y: y + 8, width: nameWidth - 8, height: rowHeight),
                    withAttributes: cellAttributes
                )
                scorebookPositionText(for: player).draw(
                    in: CGRect(x: left + numberWidth + nameWidth, y: y + 8, width: posWidth, height: rowHeight),
                    withAttributes: cellAttributes.centered
                )
            }
            // Each inning gets a compact scorekeeping box.
            for inning in 0..<innings {
                let boxX = left + numberWidth + nameWidth + posWidth + CGFloat(inning) * inningWidth
                drawAtBatBox(in: CGRect(x: boxX + 3, y: y + 4, width: inningWidth - 6, height: rowHeight - 8))
            }
        }
    }

    // MARK: - At-Bat Box Drawing
    // Draws a small diamond and scoring boxes inside a single plate appearance cell.
    private func drawAtBatBox(in rect: CGRect) {
        // Use a lighter stroke so the box does not overpower handwritten notes.
        UIColor.black.withAlphaComponent(0.45).setStroke()
        // Diamond represents the base path for scoring the at-bat.
        let diamond = UIBezierPath()
        diamond.move(to: CGPoint(x: rect.midX, y: rect.minY + 5))
        diamond.addLine(to: CGPoint(x: rect.maxX - 5, y: rect.midY))
        diamond.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - 5))
        diamond.addLine(to: CGPoint(x: rect.minX + 5, y: rect.midY))
        diamond.close()
        diamond.stroke()
        // Small boxes provide additional scorekeeping marks.
        let miniSize: CGFloat = 5
        for row in 0..<2 {
            for column in 0..<3 {
                let x = rect.minX + CGFloat(column) * miniSize
                let y = rect.minY + CGFloat(row) * miniSize
                UIBezierPath(rect: CGRect(x: x, y: y, width: miniSize, height: miniSize)).stroke()
            }
        }
    }

    // MARK: - Totals Section Drawing
    // Draws inning-by-inning totals for runs, hits, errors, and left on base.
    func drawScorebookTotalsSection(in pageRect: CGRect, headerAttributes: [NSAttributedString.Key: Any]) {
        // Layout constants for the totals grid near the bottom of the page.
        let left: CGFloat = 24
        let top: CGFloat = 568
        let labelWidth: CGFloat = 90
        let inningWidth: CGFloat = 38
        let rowHeight: CGFloat = 16
        let rows = ["Runs", "Hits", "Errors", "Left on Base"]
        let width = labelWidth + inningWidth * 10
        // Draw the totals table border and grid lines.
        UIColor.black.setStroke()
        UIBezierPath(rect: CGRect(x: left, y: top, width: width, height: rowHeight * CGFloat(rows.count))).stroke()
        for row in 0...rows.count {
            let y = top + CGFloat(row) * rowHeight
            UIBezierPath(rect: CGRect(x: left, y: y, width: width, height: 0.5)).stroke()
        }
        for column in 0...10 {
            let x = left + labelWidth + CGFloat(column) * inningWidth
            UIBezierPath(rect: CGRect(x: x, y: top, width: 0.5, height: rowHeight * CGFloat(rows.count))).stroke()
        }
        // Draw the row labels down the left side.
        for index in 0..<rows.count {
            rows[index].draw(in: CGRect(x: left + 4, y: top + CGFloat(index) * rowHeight + 4, width: labelWidth - 8, height: rowHeight), withAttributes: headerAttributes)
        }
    }

    // MARK: - Pitching Section Drawing
    // Draws the pitching summary table at the bottom of the scorebook page.
    func drawScorebookPitchingSection(in pageRect: CGRect, headerAttributes: [NSAttributedString.Key: Any]) {
        // Layout constants for the pitching table.
        let left: CGFloat = 24
        let top: CGFloat = 650
        let width: CGFloat = pageRect.width - 48
        let rowHeight: CGFloat = 18
        let columns = ["#", "Pitchers", "IP", "H", "R", "ER", "BB", "SO", "HB", "WP"]
        let columnWidths: [CGFloat] = [24, 120, 44, 44, 44, 44, 44, 44, 44, 44]
        // Draw the pitching table border, row lines, column headers, and dividers.
        UIColor.black.setStroke()
        UIBezierPath(rect: CGRect(x: left, y: top, width: width, height: rowHeight * 5)).stroke()
        for row in 0...5 {
            let y = top + CGFloat(row) * rowHeight
            UIBezierPath(rect: CGRect(x: left, y: y, width: width, height: 0.5)).stroke()
        }
        // Track each column boundary while drawing headers and vertical lines.
        var runningX = left
        for index in 0..<columns.count {
            columns[index].draw(in: CGRect(x: runningX, y: top + 5, width: columnWidths[index], height: rowHeight), withAttributes: headerAttributes.centered)
            runningX += columnWidths[index]
            UIBezierPath(rect: CGRect(x: runningX, y: top, width: 0.5, height: rowHeight * 5)).stroke()
        }
    }
}

// MARK: - Text Attribute Helpers
extension Dictionary where Key == NSAttributedString.Key, Value == Any {
    // Returns a copy of the attributes with centered paragraph alignment applied.
    var centered: [NSAttributedString.Key: Any] {
        // Avoid mutating the original attribute dictionary.
        var copy = self
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        copy[.paragraphStyle] = paragraphStyle
        return copy
    }
}
