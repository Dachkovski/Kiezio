import SwiftUI

enum PostCategory: String, CaseIterable, Identifiable, Codable {
    case all = "Alles"
    case questions = "Fragen"
    case recommendations = "Empfehlungen"
    case help = "Hilfe"
    case events = "Events"
    case humor = "Humor"
    case warnings = "Warnungen"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .all: "sparkles"
        case .questions: "questionmark.bubble"
        case .recommendations: "hand.thumbsup"
        case .help: "hands.sparkles"
        case .events: "calendar"
        case .humor: "face.smiling"
        case .warnings: "exclamationmark.triangle"
        }
    }

    var tint: Color {
        switch self {
        case .all: KiezioColor.ink
        case .questions: KiezioColor.blue
        case .recommendations: KiezioColor.green
        case .help: KiezioColor.teal
        case .events: KiezioColor.plum
        case .humor: KiezioColor.gold
        case .warnings: KiezioColor.red
        }
    }

    var feedSurface: Color {
        switch self {
        case .all: KiezioColor.ink
        case .questions: KiezioColor.blue
        case .recommendations: KiezioColor.green
        case .help: KiezioColor.teal
        case .events: KiezioColor.plum
        case .humor: KiezioColor.gold
        case .warnings: KiezioColor.coral
        }
    }

    var feedForeground: Color {
        switch self {
        case .humor: KiezioColor.ink
        default: .white
        }
    }

    var feedSecondaryForeground: Color {
        switch self {
        case .humor: KiezioColor.ink.opacity(0.68)
        default: .white.opacity(0.76)
        }
    }

    var softSurface: Color {
        switch self {
        case .all: KiezioColor.ink.opacity(0.10)
        default: tint.opacity(0.16)
        }
    }
}

enum ReachLevel: String, CaseIterable, Identifiable, Codable {
    case kiezio = "Nähe"
    case district = "Bezirk"
    case city = "Stadt"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .kiezio: "in deiner Nähe"
        case .district: "dein Bezirk"
        case .city: "deine Stadt"
        }
    }
}

enum ModerationStatus: String, Codable {
    case visible
    case underReview
    case removed
}

enum ReportReason: String, CaseIterable, Identifiable, Codable {
    case spam = "Spam"
    case insult = "Beleidigung"
    case harassment = "Belästigung"
    case hateSpeech = "Hate Speech"
    case sexualHarassment = "Sexuelle Belästigung"
    case privacy = "Datenschutz"
    case offTopic = "Off-topic"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .spam: "exclamationmark.bubble"
        case .insult: "person.crop.circle.badge.exclamationmark"
        case .harassment: "hand.raised"
        case .hateSpeech: "shield.lefthalf.filled"
        case .sexualHarassment: "exclamationmark.shield"
        case .privacy: "lock.shield"
        case .offTopic: "bubble.left.and.text.bubble.right"
        }
    }

    var requiresImmediateReview: Bool {
        switch self {
        case .harassment, .hateSpeech, .sexualHarassment, .privacy:
            true
        case .spam, .insult, .offTopic:
            false
        }
    }

    var reviewDetail: String {
        switch self {
        case .spam: "Spam wird begrenzt und bei Wiederholung entfernt."
        case .insult: "Beleidigungen reduzieren Reichweite und koennen zur Entfernung fuehren."
        case .harassment: "Belaestigung geht direkt in die Moderationspruefung."
        case .hateSpeech: "Hate Speech geht direkt in die Moderationspruefung."
        case .sexualHarassment: "Sexuelle Belaestigung geht direkt in die Moderationspruefung."
        case .privacy: "Datenschutz- und Doxxing-Hinweise gehen direkt in die Moderationspruefung."
        case .offTopic: "Off-topic-Meldungen helfen beim Ranking und bei Wiederholung der Pruefung."
        }
    }
}
