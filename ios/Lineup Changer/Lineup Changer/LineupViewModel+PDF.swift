//
//  LineupViewModel+PDF.swift
//  Lineup Changer
//
//  Created by Rich Morris on 5/4/26.
//

import Foundation
import UIKit

extension LineupViewModel {
    func createScorebookPDF() throws -> URL {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("LineupChangerScorebook-\(UUID().uuidString).pdf")

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        try renderer.writePDF(to: outputURL) { context in
            context.beginPage()

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

            let smallAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 6),
                .foregroundColor: UIColor.darkGray
            ]

            let title = "Lineup Changer Scorebook"
            title.draw(
                in: CGRect(x: 0, y: 18, width: pageRect.width, height: 24),
                withAttributes: titleAttributes.centered
            )

            drawScorebookInfoHeader(in: pageRect)
            drawScorebookLineupTable(
                in: pageRect,
                headerAttributes: headerAttributes,
                cellAttributes: cellAttributes,
                smallAttributes: smallAttributes
            )
            drawScorebookTotalsSection(in: pageRect, headerAttributes: headerAttributes)
            drawScorebookPitchingSection(in: pageRect, headerAttributes: headerAttributes)

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
                smallAttributes: smallAttributes,
                includePlayers: false
            )
            drawScorebookTotalsSection(in: pageRect, headerAttributes: headerAttributes)
            drawScorebookPitchingSection(in: pageRect, headerAttributes: headerAttributes)
        }

        return outputURL
    }

    private func scorebookLineupName(for player: Player) -> String {
        if player.number.isEmpty {
            return player.name
        }

        return "#\(player.number) \(player.name)"
    }

    private func scorebookPositionText(for player: Player) -> String {
        if pitcherID == player.id {
            return "P"
        }

        if catcherID == player.id {
            return "C"
        }

        if let assignedPosition = lineup.first(where: { $0.value.id == player.id })?.key {
            return assignedPosition.rawValue
        }

        return ""
    }

    private func drawScorebookInfoHeader(in pageRect: CGRect) {
        let left: CGFloat = 24
        let top: CGFloat = 52
        let width = pageRect.width - 48
        let rowHeight: CGFloat = 20
        let columnWidth = width / 3

        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 7),
            .foregroundColor: UIColor.black
        ]

        let lineColor = UIColor.black
        lineColor.setStroke()

        for row in 0...2 {
            let y = top + CGFloat(row) * rowHeight
            UIBezierPath(rect: CGRect(x: left, y: y, width: width, height: rowHeight)).stroke()
        }

        for column in 1...2 {
            let x = left + CGFloat(column) * columnWidth
            UIBezierPath(rect: CGRect(x: x, y: top, width: 0.5, height: rowHeight * 3)).stroke()
        }

        let labels = [
            ("Team:", selectedTeamName),
            ("Date:", ""),
            ("Opponent:", ""),
            ("Scorer:", ""),
            ("Start:", ""),
            ("Weather:", "")
        ]

        for index in 0..<labels.count {
            let row = index / 3
            let column = index % 3
            let x = left + CGFloat(column) * columnWidth + 6
            let y = top + CGFloat(row) * rowHeight + 5
            let text = labels[index].1.isEmpty ? labels[index].0 : "\(labels[index].0) \(labels[index].1)"
            text.draw(in: CGRect(x: x, y: y, width: columnWidth - 12, height: rowHeight), withAttributes: labelAttributes)
        }
    }

    private func drawScorebookLineupTable(
        in pageRect: CGRect,
        headerAttributes: [NSAttributedString.Key: Any],
        cellAttributes: [NSAttributedString.Key: Any],
        smallAttributes: [NSAttributedString.Key: Any],
        includePlayers: Bool = true
    ) {
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

        UIColor.black.setStroke()
        UIBezierPath(rect: CGRect(x: left, y: top, width: tableWidth, height: headerHeight + CGFloat(playerRows) * rowHeight)).stroke()

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

        "#".draw(in: CGRect(x: left, y: top + 5, width: numberWidth, height: headerHeight), withAttributes: headerAttributes.centered)
        "Line Up".draw(in: CGRect(x: left + numberWidth, y: top + 5, width: nameWidth, height: headerHeight), withAttributes: headerAttributes.centered)
        "Pos".draw(in: CGRect(x: left + numberWidth + nameWidth, y: top + 5, width: posWidth, height: headerHeight), withAttributes: headerAttributes.centered)

        for inning in 1...innings {
            let x = left + numberWidth + nameWidth + posWidth + CGFloat(inning - 1) * inningWidth
            "\(inning)".draw(in: CGRect(x: x, y: top + 5, width: inningWidth, height: headerHeight), withAttributes: headerAttributes.centered)
        }

        let statHeaders = ["AB", "R", "H", "RBI"]
        for index in 0..<statHeaders.count {
            let x = left + numberWidth + nameWidth + posWidth + CGFloat(innings) * inningWidth + CGFloat(index) * statWidth
            statHeaders[index].draw(in: CGRect(x: x, y: top + 5, width: statWidth, height: headerHeight), withAttributes: headerAttributes.centered)
        }

        let orderedPlayers = includePlayers
            ? battingOrderIDs
                .compactMap { player(for: $0) }
                .filter { $0.status == .active }
            : []
        let maxRows = includePlayers ? min(orderedPlayers.count, playerRows) : playerRows

        for index in 0..<maxRows {
            let y = top + headerHeight + CGFloat(index) * rowHeight

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

            for inning in 0..<innings {
                let boxX = left + numberWidth + nameWidth + posWidth + CGFloat(inning) * inningWidth
                drawAtBatBox(in: CGRect(x: boxX + 3, y: y + 4, width: inningWidth - 6, height: rowHeight - 8), attributes: smallAttributes)
            }
        }
    }

    private func drawAtBatBox(in rect: CGRect, attributes: [NSAttributedString.Key: Any]) {
        UIColor.black.withAlphaComponent(0.45).setStroke()

        let diamond = UIBezierPath()
        diamond.move(to: CGPoint(x: rect.midX, y: rect.minY + 5))
        diamond.addLine(to: CGPoint(x: rect.maxX - 5, y: rect.midY))
        diamond.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - 5))
        diamond.addLine(to: CGPoint(x: rect.minX + 5, y: rect.midY))
        diamond.close()
        diamond.stroke()

        let miniSize: CGFloat = 5
        for row in 0..<2 {
            for column in 0..<3 {
                let x = rect.minX + CGFloat(column) * miniSize
                let y = rect.minY + CGFloat(row) * miniSize
                UIBezierPath(rect: CGRect(x: x, y: y, width: miniSize, height: miniSize)).stroke()
            }
        }
    }

    private func drawScorebookTotalsSection(in pageRect: CGRect, headerAttributes: [NSAttributedString.Key: Any]) {
        let left: CGFloat = 24
        let top: CGFloat = 568
        let labelWidth: CGFloat = 90
        let inningWidth: CGFloat = 38
        let rowHeight: CGFloat = 16
        let rows = ["Runs", "Hits", "Errors", "Left on Base"]
        let width = labelWidth + inningWidth * 10

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

        for index in 0..<rows.count {
            rows[index].draw(in: CGRect(x: left + 4, y: top + CGFloat(index) * rowHeight + 4, width: labelWidth - 8, height: rowHeight), withAttributes: headerAttributes)
        }
    }

    private func drawScorebookPitchingSection(in pageRect: CGRect, headerAttributes: [NSAttributedString.Key: Any]) {
        let left: CGFloat = 24
        let top: CGFloat = 650
        let width: CGFloat = pageRect.width - 48
        let rowHeight: CGFloat = 18
        let columns = ["#", "Pitchers", "IP", "H", "R", "ER", "BB", "SO", "HB", "WP"]
        let columnWidths: [CGFloat] = [24, 120, 44, 44, 44, 44, 44, 44, 44, 44]

        UIColor.black.setStroke()
        UIBezierPath(rect: CGRect(x: left, y: top, width: width, height: rowHeight * 5)).stroke()

        for row in 0...5 {
            let y = top + CGFloat(row) * rowHeight
            UIBezierPath(rect: CGRect(x: left, y: y, width: width, height: 0.5)).stroke()
        }

        var runningX = left
        for index in 0..<columns.count {
            columns[index].draw(in: CGRect(x: runningX, y: top + 5, width: columnWidths[index], height: rowHeight), withAttributes: headerAttributes.centered)
            runningX += columnWidths[index]
            UIBezierPath(rect: CGRect(x: runningX, y: top, width: 0.5, height: rowHeight * 5)).stroke()
        }
    }
}

private extension Dictionary where Key == NSAttributedString.Key, Value == Any {
    var centered: [NSAttributedString.Key: Any] {
        var copy = self
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        copy[.paragraphStyle] = paragraphStyle
        return copy
    }
}
