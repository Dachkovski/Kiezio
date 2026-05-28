import SwiftUI

struct PostDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: HomeViewModel
    let postID: KiezioPost.ID
    @State private var replyText = ""
    @State private var showReport = false
    @State private var showVideoChat = false
    @State private var replyReportTarget: ReplyReportTarget?
    @State private var replyModerationWarning: ModerationResult?
    @State private var showReplyWarning = false
    private let maxReplyLength = 280
    private let minReplyLength = 2

    private var post: KiezioPost? {
        viewModel.post(with: postID)
    }

    private var trimmedReplyText: String {
        replyText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSendReply: Bool {
        trimmedReplyText.count >= minReplyLength && trimmedReplyText.count <= maxReplyLength
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KiezioSpacing.md) {
                if let post {
                    PostCardView(
                        post: post,
                        onReact: {
                            viewModel.toggleReaction(for: post.id)
                        },
                        onReport: {
                            showReport = true
                        },
                        onHide: {
                            viewModel.hide(postID: post.id)
                            dismiss()
                        },
                        onMute: {
                            viewModel.muteAuthor(postID: post.id)
                            dismiss()
                        },
                        onBlock: {
                            viewModel.blockAuthor(postID: post.id)
                            dismiss()
                        }
                    )

                    HStack(spacing: KiezioSpacing.sm) {
                        Text("Antworten")
                            .font(.headline)
                        Spacer()
                        Button {
                            showVideoChat = true
                        } label: {
                            Label("Video", systemImage: "video")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(post.videoPeer.canReceiveCalls ? KiezioColor.muted : KiezioColor.muted.opacity(0.45))
                        .disabled(!post.videoPeer.canReceiveCalls)

                        Button {
                            showReport = true
                        } label: {
                            Label("Melden", systemImage: "flag")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KiezioColor.red)
                    }

                    VStack(spacing: KiezioSpacing.sm) {
                        TextField("Hilfreich antworten", text: $replyText, axis: .vertical)
                            .lineLimit(2...5)
                            .onChange(of: replyText) { _, newValue in
                                if newValue.count > maxReplyLength {
                                    replyText = String(newValue.prefix(maxReplyLength))
                                }
                            }
                            .padding(12)
                            .background(KiezioColor.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                        HStack {
                            Label("Respektvoll und ohne private Details antworten.", systemImage: "shield")
                                .font(.caption)
                                .foregroundStyle(KiezioColor.muted)
                            Spacer()
                            Text("\(maxReplyLength - replyText.count)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(maxReplyLength - replyText.count < 24 ? KiezioColor.gold : KiezioColor.muted)
                        }

                        Button("Antwort senden") {
                            Task { await attemptReply(to: post.id, force: false) }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(!canSendReply)
                    }

                    if post.replies.isEmpty {
                        Text("Noch keine Antworten. Eine konkrete, respektvolle Antwort hilft hier am meisten.")
                            .font(.subheadline)
                            .foregroundStyle(KiezioColor.muted)
                            .kiezioCard()
                    } else {
                        ForEach(post.replies) { reply in
                            VStack(alignment: .leading, spacing: KiezioSpacing.sm) {
                                Text(reply.text)
                                    .font(.body)
                                HStack {
                                    Button {
                                        viewModel.toggleReplyReaction(postID: post.id, replyID: reply.id)
                                    } label: {
                                        Label("\(reply.reactions)", systemImage: reply.hasCurrentUserReacted ? "heart.fill" : "heart")
                                    }
                                    .buttonStyle(.plain)

                                    Spacer()
                                    Button {
                                        replyReportTarget = ReplyReportTarget(id: reply.id)
                                    } label: {
                                        Label("Melden", systemImage: "flag")
                                    }
                                    Text(reply.createdAt, style: .relative)
                                }
                                .font(.caption)
                                .foregroundStyle(KiezioColor.muted)
                            }
                            .kiezioCard()
                        }
                    }
                } else {
                    EmptyStateView()
                }
            }
            .padding(KiezioSpacing.md)
        }
        .background(KiezioColor.background)
        .navigationTitle("Beitrag")
        .inlineNavigationTitle()
        .sheet(isPresented: $showReport) {
            ReportSheetView(targetName: "Beitrag") { reason in
                viewModel.report(postID: postID, reason: reason)
            }
        }
        .sheet(isPresented: $showVideoChat) {
            if let post {
                VideoChatView(
                    peer: post.videoPeer,
                    onReport: { reason in
                        viewModel.reportVideoCall(postID: post.id, reason: reason)
                    },
                    onBlock: {
                        viewModel.blockAuthor(postID: post.id)
                    }
                )
            }
        }
        .sheet(item: $replyReportTarget) { target in
            ReportSheetView(targetName: "Antwort") { reason in
                viewModel.reportReply(postID: postID, replyID: target.id, reason: reason)
            }
        }
        .alert("Antwort pruefen", isPresented: $showReplyWarning) {
            Button("Bearbeiten", role: .cancel) {}
            Button("Trotzdem senden") {
                Task { await attemptReply(to: postID, force: true) }
            }
        } message: {
            Text(replyModerationWarning?.reason ?? "Bitte pruefe deine Antwort.")
        }
    }

    private func attemptReply(to postID: KiezioPost.ID, force: Bool) async {
        let trimmed = trimmedReplyText
        guard trimmed.count >= minReplyLength, trimmed.count <= maxReplyLength else { return }

        let result = await viewModel.evaluate(text: trimmed)
        if result.isFlagged && !force {
            replyModerationWarning = result
            showReplyWarning = true
            return
        }

        viewModel.addReply(to: postID, text: trimmed)
        replyText = ""
    }
}

private struct ReplyReportTarget: Identifiable {
    let id: PostReply.ID
}

private extension View {
    @ViewBuilder
    func inlineNavigationTitle() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}
