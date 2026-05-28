import SwiftUI

struct PostCardView: View {
    let post: KiezioPost
    let onReact: () -> Void
    var onOpen: (() -> Void)?
    var onReport: (() -> Void)?
    var onHide: (() -> Void)?
    var onMute: (() -> Void)?
    var onBlock: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: KiezioSpacing.md) {
            HStack(alignment: .top, spacing: KiezioSpacing.sm) {
                VStack(alignment: .leading, spacing: KiezioSpacing.xs) {
                    Label(post.category.rawValue, systemImage: post.category.systemImage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(post.category.feedForeground)
                    Label(post.authorDisplayName, systemImage: "person.crop.circle")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(post.category.feedSecondaryForeground)
                }
                Spacer()
                Text(post.reach.displayName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(post.category.feedSecondaryForeground)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.white.opacity(post.category == .humor ? 0.38 : 0.16), in: Capsule())
                safetyMenu
            }

            if let onOpen {
                Button(action: onOpen) {
                    postText
                }
                .buttonStyle(.plain)
            } else {
                postText
            }

            if post.moderationStatus == .underReview {
                Label("Wird transparent geprueft", systemImage: "shield.lefthalf.filled")
                    .font(.caption)
                    .foregroundStyle(post.category.feedForeground)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(post.category == .humor ? 0.34 : 0.16), in: Capsule())
            }

            HStack(spacing: KiezioSpacing.md) {
                Button(action: onReact) {
                    Label("\(post.reactions)", systemImage: post.hasCurrentUserReacted ? "heart.fill" : "heart")
                }
                .buttonStyle(.plain)

                Label("\(post.replyCount)", systemImage: "bubble.left")

                Spacer()

                Label(post.qualityLabel, systemImage: "checkmark.seal")
                    .foregroundStyle(post.category.feedSecondaryForeground)

                Text(post.createdAt, style: .relative)
                    .foregroundStyle(post.category.feedSecondaryForeground)
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(post.category.feedSecondaryForeground)
        }
        .padding(KiezioSpacing.md)
        .background(post.category.feedSurface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: post.category.feedSurface.opacity(0.18), radius: 10, y: 5)
        .opacity(post.moderationStatus == .underReview ? 0.72 : 1)
    }

    private var postText: some View {
        Text(post.text)
            .font(.body.weight(.medium))
            .foregroundStyle(post.category.feedForeground)
            .lineSpacing(3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
    }

    @ViewBuilder
    private var safetyMenu: some View {
        if onReport != nil || onHide != nil || onMute != nil || onBlock != nil {
            Menu {
                if let onReport {
                    Button(action: onReport) {
                        Label("Melden", systemImage: "flag")
                    }
                }
                if let onHide {
                    Button(action: onHide) {
                        Label("Thread ausblenden", systemImage: "eye.slash")
                    }
                }
                if let onMute {
                    Button(action: onMute) {
                        Label("Autor stummschalten", systemImage: "speaker.slash")
                    }
                }
                if let onBlock {
                    Button(role: .destructive, action: onBlock) {
                        Label("Autor blockieren", systemImage: "hand.raised")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundStyle(post.category.feedSecondaryForeground)
            }
            .accessibilityLabel("Sicherheitsaktionen")
        }
    }
}
