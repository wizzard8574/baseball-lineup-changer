// Created by Rich Morris on 5/5/26.
// Lineup Changer
// PhoneNumberFormatting.swift
//
//
//
// PhoneNumberFormatting.swift contains shared phone-number utilities.
// These helpers validate, normalize, format, and convert phone numbers into
// call/text URLs used by player and coach contact actions.
import Foundation
import SwiftUI

// MARK: - Phone Number Validation
// Returns true when the field is empty or contains exactly 10 digits.
func isPhoneNumberValidOrEmpty(_ number: String) -> Bool {
    // Strip formatting characters before validating length.
    let digits = number.filter { $0.isNumber }
    return digits.isEmpty || digits.count == 10
}

// MARK: - Phone Number Normalization
// Normalizes live text-field input into the app's phone number display format.
func normalizedPhoneInput(oldValue: String, newValue: String) -> String {
    // Allow the user to completely clear the field.
    if newValue.isEmpty { return "" }

    // Compare old and new digit-only values to detect formatted-character deletion.
    let oldDigits = oldValue.filter { $0.isNumber }
    var newDigits = newValue.filter { $0.isNumber }

    // If the user deletes a formatting character, remove the previous digit as well.
    if newDigits == oldDigits, newValue.count < oldValue.count {
        newDigits = String(oldDigits.dropLast())
    }

    // Limit input to 10 digits and return the formatted version.
    return formatPhoneNumber(String(newDigits.prefix(10)))
}

// MARK: - Phone Number Formatting
// Formats a phone number as (XXX)XXX-XXXX while preserving partial input.
func formatPhoneNumber(_ number: String) -> String {
    // Work only with digits so callers can pass formatted or unformatted text.
    let digits = number.filter { $0.isNumber }
    var result = ""

    // Phone numbers are limited to the 10-digit format used by this app.
    let limited = String(digits.prefix(10))

    // Add formatting characters when their positions are reached.
    for (index, digit) in limited.enumerated() {
        switch index {
        case 0:
            result += "("
            result.append(digit)
        case 2:
            result.append(digit)
            result += ")"
        case 3:
            result.append(digit)
        case 5:
            result.append(digit)
            result += "-"
        default:
            result.append(digit)
        }
    }

    return result
}

// MARK: - Digit Extraction
// Returns only numeric characters from a phone number string.
func phoneDigits(_ number: String) -> String {

    number.filter { $0.isNumber }

}

// MARK: - Phone URL Helpers
// Builds a tel:// URL for valid 10-digit phone numbers.
func phoneCallURL(for number: String) -> URL? {

    // Use normalized digits for URL creation.
    let digits = phoneDigits(number)

    // Do not create call links for incomplete or invalid numbers.
    guard digits.count == 10 else { return nil }

    return URL(string: "tel://\(digits)")

}

// Builds an sms: URL for valid 10-digit phone numbers.
func phoneTextURL(for number: String) -> URL? {

    // Use normalized digits for URL creation.
    let digits = phoneDigits(number)

    // Do not create text links for incomplete or invalid numbers.
    guard digits.count == 10 else { return nil }

    return URL(string: "sms:\(digits)")

}

// Builds an sms: URL for multiple valid recipients and an optional message body.
func groupTextURL(for numbers: [String], body: String) -> URL? {
    // Normalize, validate, and keep only complete 10-digit recipients.
    let recipients = numbers
        .map { phoneDigits($0) }
        .filter { $0.count == 10 }

    // A group text URL requires at least one valid recipient.
    guard !recipients.isEmpty else { return nil }

    // URLComponents safely builds the SMS URL and optional query body.
    var components = URLComponents()
    components.scheme = "sms"
    components.path = recipients.joined(separator: ",")
    // Only attach a body query item when there is meaningful message text.
    if !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        components.queryItems = [URLQueryItem(name: "body", value: body)]
    }

    return components.url
}

// MARK: - Phone Contact Menu
// Reusable SwiftUI menu that shows Call and Text actions for a valid contact number.
struct PhoneContactMenu: View {

    // Contact number displayed and used to build call/text actions.
    let number: String

    // Optional menu label override. Defaults to showing the phone number.
    var title: String? = nil

    // Shows no menu when the phone number field is empty.
    var body: some View {

        // Empty contact numbers should not display an action menu.
        if !phoneDigits(number).isEmpty {

            // Menu title uses the provided title when available.
            Menu(title ?? number) {

                // Show Call only when a valid telephone URL can be created.
                if let callURL = phoneCallURL(for: number) {

                    Link("Call", destination: callURL)

                }

                // Show Text only when a valid SMS URL can be created.
                if let textURL = phoneTextURL(for: number) {

                    Link("Text", destination: textURL)

                }

            }

        }

    }

}
