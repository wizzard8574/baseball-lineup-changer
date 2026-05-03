//
//  PhoneNumberFormatting.swift
//  Lineup Changer
//
//  Created by Rich Morris on 5/2/26.
//

import Foundation
import SwiftUI

func isPhoneNumberValidOrEmpty(_ number: String) -> Bool {
    let digits = number.filter { $0.isNumber }
    return digits.isEmpty || digits.count == 10
}

func normalizedPhoneInput(oldValue: String, newValue: String) -> String {
    if newValue.isEmpty { return "" }

    let oldDigits = oldValue.filter { $0.isNumber }
    var newDigits = newValue.filter { $0.isNumber }

    if newDigits == oldDigits, newValue.count < oldValue.count {
        newDigits = String(oldDigits.dropLast())
    }

    return formatPhoneNumber(String(newDigits.prefix(10)))
}

// Helper function for formatting phone number as (XXX)XXX-XXXX
func formatPhoneNumber(_ number: String) -> String {
    let digits = number.filter { $0.isNumber }
    var result = ""

    let limited = String(digits.prefix(10))

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

func phoneDigits(_ number: String) -> String {

    number.filter { $0.isNumber }

}

func phoneCallURL(for number: String) -> URL? {

    let digits = phoneDigits(number)

    guard digits.count == 10 else { return nil }

    return URL(string: "tel://\(digits)")

}


func phoneTextURL(for number: String) -> URL? {

    let digits = phoneDigits(number)

    guard digits.count == 10 else { return nil }

    return URL(string: "sms:\(digits)")

}

func groupTextURL(for numbers: [String], body: String) -> URL? {
    let recipients = numbers
        .map { phoneDigits($0) }
        .filter { $0.count == 10 }

    guard !recipients.isEmpty else { return nil }

    var components = URLComponents()
    components.scheme = "sms"
    components.path = recipients.joined(separator: ",")
    if !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        components.queryItems = [URLQueryItem(name: "body", value: body)]
    }

    return components.url
}

struct PhoneContactMenu: View {

    let number: String

    var title: String? = nil

    var body: some View {

        if !phoneDigits(number).isEmpty {

            Menu(title ?? number) {

                if let callURL = phoneCallURL(for: number) {

                    Link("Call", destination: callURL)

                }

                if let textURL = phoneTextURL(for: number) {

                    Link("Text", destination: textURL)

                }

            }

        }

    }

}
