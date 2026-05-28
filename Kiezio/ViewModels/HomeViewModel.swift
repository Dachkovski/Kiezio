import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    private static var syncRevision = 0

    var posts: [KiezioPost] = []
    var spaces: [KiezioSpace] = MockSpaces.all
    var selectedSpaceID: KiezioSpace.ID = MockSpaces.area.id
    var selectedCategory: PostCategory = .all
    var selectedSort: FeedSort = .quality
    var zoneName = "Demo-Kiez"
    var userTrust = LocalUserTrust.demo
    var hiddenPostIDs: Set<KiezioPost.ID> = []
    var mutedAuthorIDs: Set<String> = []
    var blockedAuthorIDs: Set<String> = []
    var safetyEvents: [SafetyEvent] = []
    var reports: [ReportRecord] = []
    var accountDeletionRequested = false
    var dataExportRequested = false
    var appealRequested = false
    var hasLoaded = false
    var persistenceNotice = "Lokal gespeichert"

    private let postService: PostService
    private let moderationService: ModerationService
    private let locationService: LocationService
    private let appStore: AppStoreService
    private let backendService: CommunityBackendService
    private var trustService: LocalTrustService

    init(
        postService: PostService? = nil,
        moderationService: ModerationService? = nil,
        locationService: LocationService? = nil,
        trustService: LocalTrustService? = nil,
        appStore: AppStoreService? = nil,
        backendService: CommunityBackendService? = nil
    ) {
        let defaultBackend = BackendAPIService()
        self.postService = postService ?? defaultBackend
        self.moderationService = moderationService ?? HeuristicModerationService()
        self.locationService = locationService ?? MockLocationService()
        self.appStore = appStore ?? UserDefaultsAppStore()
        self.backendService = backendService ?? defaultBackend
        self.trustService = trustService ?? LocalTrustService()
        self.userTrust = self.trustService.currentTrust
    }

    var visiblePosts: [KiezioPost] {
        posts
            .filter { $0.moderationStatus != .removed }
            .filter { !hiddenPostIDs.contains($0.id) }
            .filter { !mutedAuthorIDs.contains($0.authorID) }
            .filter { !blockedAuthorIDs.contains($0.authorID) }
            .filter { selectedSpaceID == MockSpaces.area.id || $0.spaceID == selectedSpaceID }
            .filter { selectedCategory == .all || $0.category == selectedCategory }
            .sorted(by: sortPosts)
    }

    var latestSafetyEvent: SafetyEvent? {
        safetyEvents.first
    }

    var hiddenPostCount: Int {
        hiddenPostIDs.count
    }

    var mutedAuthorCount: Int {
        mutedAuthorIDs.count
    }

    var blockedAuthorCount: Int {
        blockedAuthorIDs.count
    }

    var queuedReportCount: Int {
        reports.filter { $0.status == .queued }.count
    }

    var actionableReportCount: Int {
        reports.filter { $0.status == .queued || $0.status == .visibleLimited }.count
    }

    func load() async {
        guard !hasLoaded else { return }
        zoneName = await locationService.currentZone()
        let fetchedPosts = await postService.fetchPosts()

        if let snapshot = appStore.loadSnapshot() {
            posts = fetchedPosts.isEmpty ? snapshot.posts : fetchedPosts
            userTrust = snapshot.userTrust
            trustService = LocalTrustService(currentTrust: snapshot.userTrust)
            hiddenPostIDs = snapshot.hiddenPostIDs
            mutedAuthorIDs = snapshot.mutedAuthorIDs
            blockedAuthorIDs = snapshot.blockedAuthorIDs
            safetyEvents = snapshot.safetyEvents
            reports = snapshot.reports
            accountDeletionRequested = snapshot.accountDeletionRequested
            dataExportRequested = snapshot.dataExportRequested
            appealRequested = snapshot.appealRequested
            persistenceNotice = fetchedPosts.isEmpty ? "Lokale Daten geladen" : "Backend synchronisiert"
        } else {
            posts = fetchedPosts
            persistenceNotice = "Backend synchronisiert"
            persist()
        }

        hasLoaded = true
    }

    func evaluate(text: String) async -> ModerationResult {
        await moderationService.evaluate(text: text)
    }

    func createPost(text: String, category: PostCategory, spaceID: KiezioSpace.ID, reach: ReachLevel, wasFlagged: Bool) async {
        if wasFlagged {
            trustService.recordNegativeSignal()
        }
        let post = await postService.createPost(text: text, category: category, spaceID: spaceID, reach: reach, trust: trustService.currentTrust)
        posts.insert(post, at: 0)
        selectedSpaceID = spaceID
        selectedCategory = category
        selectedSort = .recent
        userTrust = trustService.currentTrust
        recordSafetyEvent(
            title: "Beitrag lokal gespeichert",
            detail: "Der Beitrag ist pseudonym im \(spaceTitle(for: spaceID))-Space sichtbar."
        )
        persist()
    }

    func toggleReaction(for postID: KiezioPost.ID) {
        guard let index = posts.firstIndex(where: { $0.id == postID }) else { return }
        posts[index].hasCurrentUserReacted.toggle()
        posts[index].reactions += posts[index].hasCurrentUserReacted ? 1 : -1
        posts[index].qualityScore = min(1, max(0, posts[index].qualityScore + (posts[index].hasCurrentUserReacted ? 0.02 : -0.02)))
        trustService.recordHelpfulAction()
        userTrust = trustService.currentTrust
        persist()
        let revision = Self.syncRevision
        Task {
            if let remotePost = try? await backendService.toggleReaction(postID: postID) {
                replacePost(remotePost, revision: revision)
            }
        }
    }

    func addReply(to postID: KiezioPost.ID, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = posts.firstIndex(where: { $0.id == postID }) else { return }
        let reply = PostReply(id: UUID(), text: trimmed, createdAt: Date(), reactions: 0, authorTrust: userTrust.score, hasCurrentUserReacted: false)
        posts[index].replies.append(reply)
        posts[index].qualityScore = min(1, posts[index].qualityScore + 0.03)
        trustService.recordHelpfulAction()
        userTrust = trustService.currentTrust
        persist()
        let revision = Self.syncRevision
        Task {
            if let remotePost = try? await backendService.addReply(postID: postID, text: trimmed) {
                replacePost(remotePost, revision: revision)
            }
        }
    }

    func toggleReplyReaction(postID: KiezioPost.ID, replyID: PostReply.ID) {
        guard let postIndex = posts.firstIndex(where: { $0.id == postID }),
              let replyIndex = posts[postIndex].replies.firstIndex(where: { $0.id == replyID }) else { return }
        posts[postIndex].replies[replyIndex].hasCurrentUserReacted.toggle()
        posts[postIndex].replies[replyIndex].reactions += posts[postIndex].replies[replyIndex].hasCurrentUserReacted ? 1 : -1
        trustService.recordHelpfulAction()
        userTrust = trustService.currentTrust
        persist()
        let revision = Self.syncRevision
        Task {
            if let remotePost = try? await backendService.toggleReplyReaction(postID: postID, replyID: replyID) {
                replacePost(remotePost, revision: revision)
            }
        }
    }

    func report(postID: KiezioPost.ID, reason: ReportReason) {
        guard let index = posts.firstIndex(where: { $0.id == postID }) else { return }
        posts[index].reportCount += 1
        let status: ModerationReviewStatus = reason.requiresImmediateReview || posts[index].reportCount >= 2 ? .visibleLimited : .queued
        reports.insert(ReportRecord(targetKind: .post, targetID: postID, reason: reason, status: status), at: 0)
        recordSafetyEvent(
            title: "Meldung erfasst",
            detail: "\(reason.rawValue): \(reason.reviewDetail)"
        )
        if reason.requiresImmediateReview || posts[index].reportCount >= 2 {
            posts[index].moderationStatus = .underReview
        }
        if posts[index].reportCount >= 4 {
            posts[index].moderationStatus = .removed
            posts[index].removalReason = "Dieser Beitrag wurde nach mehreren Meldungen wegen \(reason.rawValue) entfernt."
            reports[0].status = .removed
        }
        persist()
        let revision = Self.syncRevision
        Task {
            if let remoteReport = try? await backendService.report(targetKind: .post, targetID: postID, parentPostID: nil, reason: reason) {
                replaceNewestReport(remoteReport, revision: revision)
            }
        }
    }

    func reportReply(postID: KiezioPost.ID, replyID: PostReply.ID, reason: ReportReason) {
        guard posts.contains(where: { $0.id == postID }) else { return }
        let status: ModerationReviewStatus = reason.requiresImmediateReview ? .visibleLimited : .queued
        reports.insert(ReportRecord(targetKind: .reply, targetID: replyID, parentPostID: postID, reason: reason, status: status), at: 0)
        recordSafetyEvent(
            title: "Antwort gemeldet",
            detail: "\(reason.rawValue): Die Antwort ist in der lokalen Moderationsliste vorgemerkt."
        )
        persist()
        let revision = Self.syncRevision
        Task {
            if let remoteReport = try? await backendService.report(targetKind: .reply, targetID: replyID, parentPostID: postID, reason: reason) {
                replaceNewestReport(remoteReport, revision: revision)
            }
        }
    }

    func reportVideoCall(postID: KiezioPost.ID, reason: ReportReason) {
        guard posts.contains(where: { $0.id == postID }) else { return }
        reports.insert(ReportRecord(targetKind: .videoCall, targetID: postID, parentPostID: postID, reason: reason, status: .visibleLimited), at: 0)
        recordSafetyEvent(
            title: "Videoanruf gemeldet",
            detail: "\(reason.rawValue): Der Kontakt ist fuer die Moderationspruefung markiert."
        )
        persist()
        let revision = Self.syncRevision
        Task {
            if let remoteReport = try? await backendService.report(targetKind: .videoCall, targetID: postID, parentPostID: postID, reason: reason) {
                replaceNewestReport(remoteReport, revision: revision)
            }
        }
    }

    func hide(postID: KiezioPost.ID) {
        guard let post = post(with: postID) else { return }
        hiddenPostIDs.insert(postID)
        recordSafetyEvent(
            title: "Thread ausgeblendet",
            detail: "Der Beitrag von \(post.authorDisplayName) ist aus deinem Feed entfernt."
        )
        persist()
        Task {
            try? await backendService.setControl(kind: .hide, targetID: postID.uuidString)
        }
    }

    func muteAuthor(postID: KiezioPost.ID) {
        guard let post = post(with: postID) else { return }
        mutedAuthorIDs.insert(post.authorID)
        recordSafetyEvent(
            title: "Autor stummgeschaltet",
            detail: "Neue Beitraege von \(post.authorDisplayName) werden lokal ausgeblendet."
        )
        persist()
        Task {
            try? await backendService.setControl(kind: .mute, targetID: post.authorID)
        }
    }

    func blockAuthor(postID: KiezioPost.ID) {
        guard let post = post(with: postID) else { return }
        blockedAuthorIDs.insert(post.authorID)
        hiddenPostIDs.insert(postID)
        recordSafetyEvent(
            title: "Autor blockiert",
            detail: "\(post.authorDisplayName) kann in diesem Prototyp nicht mehr im Feed erscheinen."
        )
        persist()
        Task {
            try? await backendService.setControl(kind: .block, targetID: post.authorID)
        }
    }

    func requestAccountDeletion() {
        accountDeletionRequested = true
        recordSafetyEvent(
            title: "Loeschanfrage vorgemerkt",
            detail: "Die App sendet die Loeschung ans Backend und entfernt lokale Kontrolldaten."
        )
        persist()
    }

    func requestDataExport() {
        dataExportRequested = true
        recordSafetyEvent(
            title: "Datenexport erstellt",
            detail: "Der Export enthaelt Feed-, Safety-, Backend- und Kontrolldaten dieses Accounts."
        )
        persist()
    }

    func requestAppeal() {
        appealRequested = true
        recordSafetyEvent(
            title: "Einspruch vorgemerkt",
            detail: "Moderationsentscheidungen brauchen spaeter eine Regel-ID und einen pruefbaren Einspruch."
        )
        persist()
    }

    func resetLocalData() async {
        Self.syncRevision += 1
        appStore.clear()
        posts = await postService.fetchPosts()
        hiddenPostIDs = []
        mutedAuthorIDs = []
        blockedAuthorIDs = []
        safetyEvents = []
        reports = []
        accountDeletionRequested = false
        dataExportRequested = false
        appealRequested = false
        trustService = LocalTrustService()
        userTrust = trustService.currentTrust
        persistenceNotice = "Demo-Daten zurueckgesetzt"
        persist()
    }

    func deleteLocalAccountData() async {
        Self.syncRevision += 1
        appStore.clear()
        posts = []
        hiddenPostIDs = []
        mutedAuthorIDs = []
        blockedAuthorIDs = []
        safetyEvents = []
        reports = []
        accountDeletionRequested = true
        dataExportRequested = false
        appealRequested = false
        trustService = LocalTrustService()
        userTrust = trustService.currentTrust
        persistenceNotice = "Lokale Accountdaten geloescht"
        hasLoaded = false
        try? await backendService.deleteAccount()
        AppConfiguration.rotateAPIUserIDAfterAccountDeletion()
    }

    func makeDataExportText() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(currentSnapshot),
              let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }

        return json
    }

    func makeBackendDataExportText() async -> String {
        requestDataExport()
        if let remoteExport = try? await backendService.exportUserData() {
            return remoteExport
        }
        return makeDataExportText()
    }

    func post(with id: KiezioPost.ID) -> KiezioPost? {
        posts.first { $0.id == id }
    }

    func postCount(for spaceID: KiezioSpace.ID) -> Int {
        visiblePosts.filter { spaceID == MockSpaces.area.id || $0.spaceID == spaceID }.count
    }

    func defaultSpaceID(for category: PostCategory) -> KiezioSpace.ID {
        switch category {
        case .questions: MockSpaces.questions.id
        case .recommendations: MockSpaces.recommendations.id
        case .help: MockSpaces.help.id
        case .events: MockSpaces.events.id
        case .warnings: MockSpaces.mobility.id
        case .humor, .all: MockSpaces.area.id
        }
    }

    private func recordSafetyEvent(title: String, detail: String) {
        safetyEvents.insert(SafetyEvent(title: title, detail: detail), at: 0)
        if safetyEvents.count > 10 {
            safetyEvents = Array(safetyEvents.prefix(10))
        }
    }

    private func sortPosts(_ lhs: KiezioPost, _ rhs: KiezioPost) -> Bool {
        switch selectedSort {
        case .quality:
            let lhsRank = lhs.qualityScore + lhs.authorTrust - (lhs.moderationStatus == .underReview ? 0.7 : 0)
            let rhsRank = rhs.qualityScore + rhs.authorTrust - (rhs.moderationStatus == .underReview ? 0.7 : 0)
            return lhsRank == rhsRank ? lhs.createdAt > rhs.createdAt : lhsRank > rhsRank
        case .recent:
            return lhs.createdAt > rhs.createdAt
        }
    }

    private func spaceTitle(for id: KiezioSpace.ID) -> String {
        spaces.first { $0.id == id }?.title ?? "Kiezio"
    }

    private func persist() {
        appStore.save(snapshot: currentSnapshot)
    }

    private func replacePost(_ post: KiezioPost, revision: Int) {
        guard revision == Self.syncRevision else { return }
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index] = post
        } else {
            posts.insert(post, at: 0)
        }
        persist()
    }

    private func replaceNewestReport(_ report: ReportRecord, revision: Int) {
        guard revision == Self.syncRevision else { return }
        if let index = reports.firstIndex(where: { $0.targetKind == report.targetKind && $0.targetID == report.targetID && $0.reason == report.reason }) {
            reports[index] = report
        } else {
            reports.insert(report, at: 0)
        }
        persist()
    }

    private var currentSnapshot: KiezioAppSnapshot {
        KiezioAppSnapshot(
            posts: posts,
            userTrust: userTrust,
            hiddenPostIDs: hiddenPostIDs,
            mutedAuthorIDs: mutedAuthorIDs,
            blockedAuthorIDs: blockedAuthorIDs,
            safetyEvents: safetyEvents,
            reports: reports,
            accountDeletionRequested: accountDeletionRequested,
            dataExportRequested: dataExportRequested,
            appealRequested: appealRequested
        )
    }
}
