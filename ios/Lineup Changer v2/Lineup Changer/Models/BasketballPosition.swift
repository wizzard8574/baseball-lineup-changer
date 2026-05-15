import Foundation

enum BasketballPosition: String, CaseIterable, Identifiable, Codable {
    case one = "1"
    case two = "2"
    case three = "3"
    case four = "4"
    case five = "5"

    var id: String { rawValue }

    var lineupBubbleLabel: String {
        switch self {
        case .one:
            return "1-G"
        case .two:
            return "2-G"
        case .three:
            return "3-F"
        case .four:
            return "4-F"
        case .five:
            return "5-C"
        }
    }
}
