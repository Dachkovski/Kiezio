import Foundation

protocol ModerationService {
    func evaluate(text: String) async -> ModerationResult
}

struct HeuristicModerationService: ModerationService {
    private let blockedTerms = ["idiot", "arsch", "hass", "dummkopf"]
    private let threatTerms = ["ich finde dich", "ich mache dich fertig", "du wirst sehen", "drohung", "schlag dich"]
    private let privacyTerms = ["adresse", "telefonnummer", "handynummer", "wohnort", "wohnt in", "klarname"]
    private let sexualHarassmentTerms = ["nacktbild", "sexuell", "belästige", "belaestige"]

    func evaluate(text: String) async -> ModerationResult {
        let normalized = text.lowercased()
        let repeatedLinkCount = normalized.components(separatedBy: "http").count - 1
        let hasInsult = blockedTerms.contains { normalized.contains($0) }
        let hasThreat = threatTerms.contains { normalized.contains($0) }
        let hasPrivacyRisk = privacyTerms.contains { normalized.contains($0) }
        let hasSexualHarassment = sexualHarassmentTerms.contains { normalized.contains($0) }
        let looksLikeSpam = repeatedLinkCount > 1 || normalized.filter { $0 == "!" }.count > 6
        let hasPhoneNumber = normalized.range(of: #"\b(\+?\d[\d\s\/-]{7,}\d)\b"#, options: .regularExpression) != nil

        if hasThreat {
            return ModerationResult(isFlagged: true, reason: "Der Text wirkt bedrohlich. Drohungen gehoeren nicht in Kiezio und muessen geprueft werden.", severity: 0.94)
        }

        if hasPrivacyRisk || hasPhoneNumber {
            return ModerationResult(isFlagged: true, reason: "Der Text koennte private Daten oder identifizierende Hinweise enthalten. Bitte entferne Namen, Adressen oder Telefonnummern.", severity: 0.86)
        }

        if hasSexualHarassment {
            return ModerationResult(isFlagged: true, reason: "Der Text wirkt sexuell belaestigend. Solche Inhalte muessen vor dem Posten entfernt werden.", severity: 0.88)
        }

        if hasInsult {
            return ModerationResult(isFlagged: true, reason: "Der Text wirkt beleidigend. Kiezio bevorzugt klare, respektvolle lokale Hinweise.", severity: 0.72)
        }

        if looksLikeSpam {
            return ModerationResult(isFlagged: true, reason: "Der Text wirkt wie Spam oder sehr werblich. Bitte pruefe, ob er lokal hilfreich ist.", severity: 0.62)
        }

        return ModerationResult(isFlagged: false, reason: nil, severity: 0)
    }
}
