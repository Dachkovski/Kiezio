import Foundation

struct VideoPeer: Identifiable, Codable, Equatable {
    let id: String
    var displayName: String
    var areaLabel: String
    var trustScore: Double
    var canReceiveCalls: Bool

    var trustLabel: String {
        switch trustScore {
        case 0.82...: "verlaesslich"
        case 0.58...: "normal"
        default: "neu"
        }
    }
}

enum VideoCallState: String, Codable, Equatable {
    case idle
    case requesting
    case ringing
    case connecting
    case active
    case ended
    case blocked

    var title: String {
        switch self {
        case .idle: "Bereit"
        case .requesting: "Anfrage"
        case .ringing: "Eingehender Anruf"
        case .connecting: "Verbindung"
        case .active: "Im Gespraech"
        case .ended: "Beendet"
        case .blocked: "Blockiert"
        }
    }
}

struct VideoCallSession: Identifiable, Codable, Equatable {
    let id: UUID
    var peer: VideoPeer
    var state: VideoCallState
    var startedAt: Date?
    var endedAt: Date?
    var isMuted: Bool
    var isCameraEnabled: Bool
    var safetyAccepted: Bool
}

struct MediaPermissionState: Equatable {
    var cameraGranted: Bool
    var microphoneGranted: Bool

    var isReady: Bool {
        cameraGranted && microphoneGranted
    }
}

extension KiezioPost {
    var videoPeer: VideoPeer {
        VideoPeer(
            id: "post-author-\(id.uuidString)",
            displayName: authorDisplayName,
            areaLabel: reach.displayName,
            trustScore: authorTrust,
            canReceiveCalls: moderationStatus == .visible
        )
    }
}
