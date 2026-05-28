import Foundation

#if DEBUG
@MainActor
enum MVPSelfCheck {
    static func runIfRequested() async {
        guard ProcessInfo.processInfo.environment["KIEZIO_RUN_SELF_CHECKS"] == "1" else { return }

        do {
            try await run()
            writeResult("PASS")
            print("KIEZIO_SELF_CHECK: PASS")
        } catch {
            writeResult("FAIL \(error.localizedDescription)")
            print("KIEZIO_SELF_CHECK: FAIL \(error.localizedDescription)")
        }
    }

    private static func run() async throws {
        try await checkModeration()
        try checkPersistenceRoundtrip()
        try await checkFeedActions()
    }

    private static func checkModeration() async throws {
        let moderation = HeuristicModerationService()
        let blocked = await moderation.evaluate(text: "Das ist idiotisch und hilft niemandem.")
        try require(blocked.isFlagged, "Moderation muss Beleidigungen markieren.")

        let spam = await moderation.evaluate(text: "Schaut http://eins.test und http://zwei.test !!!")
        try require(spam.isFlagged, "Moderation muss Link-Spam markieren.")

        let privateData = await moderation.evaluate(text: "Hier ist die Telefonnummer 0176 12345678.")
        try require(privateData.isFlagged, "Moderation muss private Kontaktinformationen markieren.")

        let normal = await moderation.evaluate(text: "Welche Werkstatt ist samstags offen?")
        try require(!normal.isFlagged, "Moderation darf normale lokale Fragen nicht blockieren.")
    }

    private static func checkPersistenceRoundtrip() throws {
        let suiteName = "kiezio.mvp.selfcheck.store"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw SelfCheckError(message: "Test-UserDefaults konnten nicht erstellt werden.")
        }
        defaults.removePersistentDomain(forName: suiteName)

        let store = UserDefaultsAppStore(defaults: defaults)
        let posts = MockPosts.make()
        let snapshot = KiezioAppSnapshot(
            posts: posts,
            userTrust: .demo,
            hiddenPostIDs: [posts[0].id],
            mutedAuthorIDs: [posts[1].authorID],
            blockedAuthorIDs: [posts[2].authorID],
            safetyEvents: [SafetyEvent(title: "Test", detail: "Roundtrip")],
            reports: [ReportRecord(targetKind: .post, targetID: posts[0].id, reason: .harassment)],
            accountDeletionRequested: true,
            dataExportRequested: true,
            appealRequested: true
        )

        store.save(snapshot: snapshot)
        try require(store.loadSnapshot() == snapshot, "Persistenz-Roundtrip muss alle MVP-Daten erhalten.")
        store.clear()
        try require(store.loadSnapshot() == nil, "Persistenz-Clear muss lokale MVP-Daten entfernen.")
    }

    private static func checkFeedActions() async throws {
        let suiteName = "kiezio.mvp.selfcheck.feed"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw SelfCheckError(message: "Feed-Test-UserDefaults konnten nicht erstellt werden.")
        }
        defaults.removePersistentDomain(forName: suiteName)

        let store = UserDefaultsAppStore(defaults: defaults)
        let viewModel = HomeViewModel(appStore: store)
        await viewModel.load()

        let initialCount = viewModel.posts.count
        try require(initialCount > 0, "Feed muss Demo-Beitraege laden.")

        await viewModel.createPost(
            text: "Suche eine ruhige Ecke zum Arbeiten mit gutem WLAN.",
            category: .questions,
            spaceID: MockSpaces.questions.id,
            reach: .district,
            wasFlagged: false
        )

        let createdPost = try requireValue(viewModel.posts.first, "Neuer Beitrag muss oben im Feed stehen.")
        try require(viewModel.posts.count == initialCount + 1, "Neuer Beitrag muss im Feed erscheinen.")
        try require(viewModel.selectedSort == .recent, "Nach dem Posten muss der Feed auf Neu springen.")

        viewModel.toggleReaction(for: createdPost.id)
        try require(viewModel.post(with: createdPost.id)?.hasCurrentUserReacted == true, "Post-Reaktion muss toggeln.")

        viewModel.addReply(to: createdPost.id, text: "Das Cafe am Markt ist morgens ruhig.")
        let reply = try requireValue(viewModel.post(with: createdPost.id)?.replies.first, "Antwort muss gespeichert werden.")

        viewModel.toggleReplyReaction(postID: createdPost.id, replyID: reply.id)
        try require(viewModel.post(with: createdPost.id)?.replies.first?.hasCurrentUserReacted == true, "Reply-Reaktion muss toggeln.")

        viewModel.reportReply(postID: createdPost.id, replyID: reply.id, reason: .spam)
        viewModel.reportVideoCall(postID: createdPost.id, reason: .harassment)
        viewModel.report(postID: createdPost.id, reason: .privacy)
        try require(viewModel.queuedReportCount > 0, "Meldungen muessen in der Safety-Queue sichtbar werden.")
        try require(viewModel.reports.contains { $0.targetKind == .videoCall }, "Videoanruf-Meldungen muessen in der Moderationsliste landen.")

        let export = viewModel.makeDataExportText()
        try require(export.contains("\"posts\""), "Datenexport muss lokale Posts enthalten.")

        viewModel.hide(postID: createdPost.id)
        try require(!viewModel.visiblePosts.contains { $0.id == createdPost.id }, "Ausgeblendete Beitraege duerfen nicht sichtbar bleiben.")

        let reloaded = HomeViewModel(appStore: store)
        await reloaded.load()
        try require(!reloaded.reports.isEmpty, "Meldungen muessen nach Reload erhalten bleiben.")
        try require(reloaded.hiddenPostIDs.contains(createdPost.id), "Ausgeblendete Beitraege muessen nach Reload erhalten bleiben.")

        await reloaded.deleteLocalAccountData()
        let afterDeletion = HomeViewModel(appStore: store)
        await afterDeletion.load()
        try require(afterDeletion.reports.isEmpty, "Account-Loeschung muss lokale Meldedaten entfernen.")
        try require(!afterDeletion.hiddenPostIDs.contains(createdPost.id), "Account-Loeschung muss lokale Blockier-/Hide-Daten entfernen.")
    }

    private static func require(_ condition: Bool, _ message: String) throws {
        if !condition {
            throw SelfCheckError(message: message)
        }
    }

    private static func requireValue<T>(_ value: T?, _ message: String) throws -> T {
        guard let value else {
            throw SelfCheckError(message: message)
        }
        return value
    }

    private static func writeResult(_ result: String) {
        guard let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let url = directory.appendingPathComponent("mvp-self-check.txt")
        let payload = "KIEZIO_SELF_CHECK: \(result)\n"
        try? payload.write(to: url, atomically: true, encoding: .utf8)
    }
}

private struct SelfCheckError: LocalizedError {
    let message: String

    var errorDescription: String? {
        message
    }
}
#endif
