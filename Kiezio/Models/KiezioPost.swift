import Foundation

struct KiezioPost: Identifiable, Codable, Equatable {
    let id: UUID
    var authorID: String
    var authorDisplayName: String
    var spaceID: KiezioSpace.ID
    var text: String
    var category: PostCategory
    var reach: ReachLevel
    var createdAt: Date
    var reactions: Int
    var replies: [PostReply]
    var qualityScore: Double
    var authorTrust: Double
    var reportCount: Int
    var moderationStatus: ModerationStatus
    var removalReason: String?
    var hasCurrentUserReacted: Bool

    var replyCount: Int { replies.count }

    var qualityLabel: String {
        switch qualityScore {
        case 0.82...: "hilfreich"
        case 0.58...: "solide"
        default: "neu"
        }
    }
}

struct PostReply: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String
    var createdAt: Date
    var reactions: Int
    var authorTrust: Double
    var hasCurrentUserReacted: Bool
}

struct LocalUserTrust: Codable, Equatable {
    var score: Double
    var helpfulActions: Int
    var negativeSignals: Int

    static let demo = LocalUserTrust(score: 0.72, helpfulActions: 8, negativeSignals: 1)
}

struct ModerationResult: Equatable {
    var isFlagged: Bool
    var reason: String?
    var severity: Double
}
