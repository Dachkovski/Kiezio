import SwiftUI

enum SpaceKind: String, Codable {
    case area
    case campus
    case work
    case interest
    case events
    case help
}

struct KiezioSpace: Identifiable, Codable, Equatable {
    let id: String
    var title: String
    var subtitle: String
    var kind: SpaceKind
    var systemImage: String
    var tintName: String

    var tint: Color {
        switch tintName {
        case "blue": KiezioColor.blue
        case "green": KiezioColor.green
        case "plum": KiezioColor.plum
        case "gold": KiezioColor.gold
        case "red": KiezioColor.red
        default: KiezioColor.teal
        }
    }
}
