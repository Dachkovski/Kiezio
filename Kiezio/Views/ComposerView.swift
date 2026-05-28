import SwiftUI

struct ComposerView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: HomeViewModel
    @State private var text = ""
    @State private var category: PostCategory = .questions
    @State private var spaceID: KiezioSpace.ID
    @State private var reach: ReachLevel = .district
    @State private var moderationWarning: ModerationResult?
    @State private var showWarning = false
    @State private var isPosting = false
    private let maxLength = 280
    private let minLength = 8

    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        _spaceID = State(initialValue: viewModel.selectedSpaceID == MockSpaces.area.id ? MockSpaces.questions.id : viewModel.selectedSpaceID)
    }

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canPost: Bool {
        trimmedText.count >= minLength && trimmedText.count <= maxLength && !isPosting
    }

    private var remainingCharacters: Int {
        maxLength - text.count
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Was ist gerade lokal hilfreich?", text: $text, axis: .vertical)
                        .lineLimit(5...9)
                        .onChange(of: text) { _, newValue in
                            if newValue.count > maxLength {
                                text = String(newValue.prefix(maxLength))
                            }
                        }
                    HStack {
                        Label("Keine Namen, Adressen oder identifizierende Details posten.", systemImage: "lock.shield")
                        Spacer()
                        Text("\(remainingCharacters)")
                            .foregroundStyle(remainingCharacters < 24 ? KiezioColor.gold : KiezioColor.muted)
                    }
                    .font(.caption)
                    .foregroundStyle(KiezioColor.muted)
                }

                Section("Space") {
                    Picker("Raum", selection: $spaceID) {
                        ForEach(viewModel.spaces.filter { $0.id != MockSpaces.area.id }) { space in
                            Label(space.title, systemImage: space.systemImage).tag(space.id)
                        }
                    }
                    Picker("Kategorie", selection: $category) {
                        ForEach(PostCategory.allCases.filter { $0 != .all }) { item in
                            Label(item.rawValue, systemImage: item.systemImage).tag(item)
                        }
                    }
                    Picker("Reichweite", selection: $reach) {
                        ForEach(ReachLevel.allCases) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                }

                Section {
                    Label("Nur grobe Zonen, keine genaue Entfernung. Beitraege bleiben pseudonym.", systemImage: "lock")
                        .font(.footnote)
                        .foregroundStyle(KiezioColor.muted)
                    Label("Moderation markiert riskante Texte vor dem Posten und senkt bei Wiederholung die Reichweite.", systemImage: "shield.checkered")
                        .font(.footnote)
                        .foregroundStyle(KiezioColor.muted)
                }
            }
            .navigationTitle("Neuer Beitrag")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                        .accessibilityIdentifier("composer.cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Posten") {
                        Task { await attemptPost(force: false) }
                    }
                    .disabled(!canPost)
                    .accessibilityLabel("Posten")
                    .accessibilityIdentifier("composer.post")
                }
            }
            .alert("Vor dem Posten pruefen", isPresented: $showWarning) {
                Button("Bearbeiten", role: .cancel) {}
                Button("Trotzdem posten") {
                    Task { await attemptPost(force: true) }
                }
            } message: {
                Text(moderationWarning?.reason ?? "Bitte pruefe deinen Text.")
            }
        }
    }

    private func attemptPost(force: Bool) async {
        let trimmed = trimmedText
        guard !trimmed.isEmpty else { return }
        guard trimmed.count >= minLength, trimmed.count <= maxLength else { return }
        isPosting = true
        let result = await viewModel.evaluate(text: trimmed)
        if result.isFlagged && !force {
            moderationWarning = result
            showWarning = true
            isPosting = false
            return
        }
        await viewModel.createPost(text: trimmed, category: category, spaceID: spaceID, reach: reach, wasFlagged: result.isFlagged)
        isPosting = false
        dismiss()
    }
}
