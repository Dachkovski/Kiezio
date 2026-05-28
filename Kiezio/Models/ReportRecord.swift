import Foundation

enum ReportTargetKind: String, Codable, Equatable {
    case post
    case reply
    case videoCall
}

struct ReportRecord: Identifiable, Codable, Equatable {
    let id: UUID
    var targetKind: ReportTargetKind
    var targetID: UUID
    var parentPostID: UUID?
    var reason: ReportReason
    var createdAt: Date
    var status: ModerationReviewStatus

    init(
        id: UUID = UUID(),
        targetKind: ReportTargetKind,
        targetID: UUID,
        parentPostID: UUID? = nil,
        reason: ReportReason,
        createdAt: Date = Date(),
        status: ModerationReviewStatus = .queued
    ) {
        self.id = id
        self.targetKind = targetKind
        self.targetID = targetID
        self.parentPostID = parentPostID
        self.reason = reason
        self.createdAt = createdAt
        self.status = status
    }
}

enum ModerationReviewStatus: String, Codable, Equatable {
    case queued
    case visibleLimited
    case removed

    var displayName: String {
        switch self {
        case .queued: "in Pruefung"
        case .visibleLimited: "Reichweite begrenzt"
        case .removed: "entfernt"
        }
    }
}
