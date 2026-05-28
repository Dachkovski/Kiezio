import Foundation

enum FeedSort: String, CaseIterable, Identifiable, Codable {
    case quality = "Hilfreich"
    case recent = "Neu"

    var id: String { rawValue }
}
