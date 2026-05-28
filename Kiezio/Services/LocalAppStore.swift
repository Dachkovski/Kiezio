import Foundation

struct KiezioAppSnapshot: Codable, Equatable {
    var posts: [KiezioPost]
    var userTrust: LocalUserTrust
    var hiddenPostIDs: Set<KiezioPost.ID>
    var mutedAuthorIDs: Set<String>
    var blockedAuthorIDs: Set<String>
    var safetyEvents: [SafetyEvent]
    var reports: [ReportRecord]
    var accountDeletionRequested: Bool
    var dataExportRequested: Bool
    var appealRequested: Bool
}

protocol AppStoreService {
    func loadSnapshot() -> KiezioAppSnapshot?
    func save(snapshot: KiezioAppSnapshot)
    func clear()
}

struct UserDefaultsAppStore: AppStoreService {
    private let defaults: UserDefaults
    private let key = "kiezio.mvp.snapshot.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadSnapshot() -> KiezioAppSnapshot? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(KiezioAppSnapshot.self, from: data)
    }

    func save(snapshot: KiezioAppSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key)
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}
