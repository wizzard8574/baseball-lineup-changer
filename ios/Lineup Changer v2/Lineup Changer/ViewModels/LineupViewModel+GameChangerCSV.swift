// Created by Rich Morris on 5/5/26.
// Lineup Changer
// LineupViewModel+GameChangerCSV.swift
//
//
//
// GameChanger CSV parsing and normalization helpers.
import Foundation

// MARK: - GameChanger CSV Helpers
extension LineupViewModel {
    // MARK: - CSV Parsing Helpers
    // Safely reads a CSV field and returns an em dash when the value is missing or empty.
    func value(from row: [String], at index: Int?) -> String {
        guard let index, row.indices.contains(index) else { return "—" }
        let trimmed = row[index].trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "—" : trimmed
    }

    // MARK: CSV Normalization
    // Normalizes CSV headers by removing spacing and punctuation differences.
    func normalizeHeader(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Normalizes player names for matching by lowercasing and keeping only alphanumeric tokens.
    func normalizePlayerName(_ value: String) -> String {
        value
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: CSV Escaping
    // Escapes a string for CSV output by quoting values with commas, quotes, or line breaks.
    func csvEscapedValue(_ value: String) -> String {
        let needsQuotes = value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r")
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return needsQuotes ? "\"\(escaped)\"" : escaped
    }

    // MARK: CSV Parser
    // Lightweight CSV parser that supports quoted fields, escaped quotes, commas, and newlines.
    func parseCSV(_ text: String) -> [[String]] {
        // Accumulate parsed rows, the current row, and the current field being read.
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var insideQuotes = false
        var iterator = Array(text).makeIterator()

        while let character = iterator.next() {
            // Quoted sections can contain commas and newlines without ending the field.
            if character == "\"" {
                // A doubled quote inside quoted text represents a literal quote character.
                if insideQuotes, let nextCharacter = iterator.next() {
                    if nextCharacter == "\"" {
                        field.append("\"")
                    } else {
                        insideQuotes = false
                        if nextCharacter == "," {
                            row.append(field)
                            field = ""
                        } else if nextCharacter == "\n" {
                            row.append(field)
                            rows.append(row)
                            row = []
                            field = ""
                        } else if nextCharacter != "\r" {
                            field.append(nextCharacter)
                        }
                    }
                } else {
                    insideQuotes.toggle()
                }
            } else if character == ",", !insideQuotes {
                // A comma outside quotes ends the current field.
                row.append(field)
                field = ""
            } else if character == "\n", !insideQuotes {
                // A newline outside quotes ends the current row.
                row.append(field)
                rows.append(row)
                row = []
                field = ""
            } else if character != "\r" {
                field.append(character)
            }
        }

        // Add the final field/row when the file does not end with a newline.
        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            rows.append(row)
        }

        // Drop fully blank rows so import logic only sees meaningful records.
        return rows.filter { !$0.allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } }
    }
}
