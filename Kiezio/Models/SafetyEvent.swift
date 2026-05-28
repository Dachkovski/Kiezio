import Foundation

struct SafetyEvent: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var detail: String
    var createdAt: Date

    init(id: UUID = UUID(), title: String, detail: String, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.detail = detail
        self.createdAt = createdAt
    }
}
