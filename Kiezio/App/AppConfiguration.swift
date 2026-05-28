import Foundation

enum AppConfiguration {
    private static var storedAPIUserIDKey: String { "kiezio.api.user.id" }

    static var appName: String { "Kiezio" }
    static var onboardingCompletedKey: String { "kiezio.onboarding.completed" }
    static var apiBaseURL: URL { URL(string: ProcessInfo.processInfo.environment["KIEZIO_API_BASE_URL"] ?? "http://127.0.0.1:8787")! }
    static var apiUserID: String {
        if let override = ProcessInfo.processInfo.environment["KIEZIO_API_USER_ID"], !override.isEmpty {
            return override
        }

        if let storedID = UserDefaults.standard.string(forKey: storedAPIUserIDKey), !storedID.isEmpty {
            return storedID
        }

        let generatedID = "ios-\(UUID().uuidString)"
        UserDefaults.standard.set(generatedID, forKey: storedAPIUserIDKey)
        return generatedID
    }

    static var hasAPIUserIDOverride: Bool {
        ProcessInfo.processInfo.environment["KIEZIO_API_USER_ID"]?.isEmpty == false
    }

    static func rotateAPIUserIDAfterAccountDeletion() {
        guard !hasAPIUserIDOverride else { return }
        UserDefaults.standard.set("ios-\(UUID().uuidString)", forKey: storedAPIUserIDKey)
    }

    static var supportEmail: String { "support@kiezio.app" }
    static var supportMailURL: URL { URL(string: "mailto:\(supportEmail)")! }
    static var privacyPolicyURL: URL { URL(string: "https://kiezio.app/privacy")! }
    static var termsURL: URL { URL(string: "https://kiezio.app/terms")! }
    static var supportURL: URL { URL(string: "https://kiezio.app/support")! }
}
