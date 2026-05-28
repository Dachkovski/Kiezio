import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var path: [KiezioPost.ID] = []
    @State private var showComposer = false
    @State private var showSafetyCenter = false
    @State private var reportTarget: ReportTarget?
    let onAccountDeleted: () -> Void

    init(onAccountDeleted: @escaping () -> Void = {}) {
        self.onAccountDeleted = onAccountDeleted
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: KiezioSpacing.md) {
                    header
                    safetyNotice
                    spaceStrip
                    sortStrip
                    categoryStrip

                    if viewModel.visiblePosts.isEmpty {
                        EmptyStateView()
                            .padding(.top, KiezioSpacing.md)
                    } else {
                        LazyVStack(spacing: KiezioSpacing.md) {
                            ForEach(viewModel.visiblePosts) { post in
                                PostCardView(
                                    post: post,
                                    onReact: {
                                        viewModel.toggleReaction(for: post.id)
                                    },
                                    onOpen: {
                                        path.append(post.id)
                                    },
                                    onReport: {
                                        reportTarget = ReportTarget(id: post.id)
                                    },
                                    onHide: {
                                        withAnimation(.snappy) {
                                            viewModel.hide(postID: post.id)
                                        }
                                    },
                                    onMute: {
                                        withAnimation(.snappy) {
                                            viewModel.muteAuthor(postID: post.id)
                                        }
                                    },
                                    onBlock: {
                                        withAnimation(.snappy) {
                                            viewModel.blockAuthor(postID: post.id)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, KiezioSpacing.md)
                    }
                }
                .padding(.bottom, 96)
            }
            .background(KiezioColor.background)
            .navigationTitle(AppConfiguration.appName)
            .navigationDestination(for: KiezioPost.ID.self) { postID in
                PostDetailView(viewModel: viewModel, postID: postID)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSafetyCenter = true
                    } label: {
                        Image(systemName: "shield.checkered")
                    }
                    .accessibilityLabel("Safety Center")
                }
                ToolbarItem(placement: .automatic) {
                    Button {
                        showComposer = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .accessibilityLabel("Beitrag erstellen")
                }
            }
            .overlay(alignment: .bottomTrailing) {
                Button {
                    showComposer = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(KiezioColor.ink, in: Circle())
                        .shadow(color: .black.opacity(0.16), radius: 16, y: 8)
                }
                .padding(KiezioSpacing.lg)
                .accessibilityLabel("Beitrag erstellen")
            }
            .sheet(isPresented: $showComposer) {
                ComposerView(viewModel: viewModel)
            }
            .sheet(isPresented: $showSafetyCenter) {
                SafetyCenterView(viewModel: viewModel, onAccountDeleted: onAccountDeleted)
            }
            .sheet(item: $reportTarget) { target in
                ReportSheetView { reason in
                    viewModel.report(postID: target.id, reason: reason)
                }
            }
            .task {
                if viewModel.posts.isEmpty {
                    await viewModel.load()
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: KiezioSpacing.sm) {
            Label(viewModel.zoneName, systemImage: "location")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.82))
            Text("Lokale Fragen, Empfehlungen und Hilfe aus deiner Umgebung.")
                .font(.title2.bold())
                .foregroundStyle(.white)
            HStack(spacing: KiezioSpacing.sm) {
                Label("pseudonym", systemImage: "person.crop.circle.badge.checkmark")
                Label("grobe Zone", systemImage: "map")
                Label("moderiert", systemImage: "shield")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.white.opacity(0.72))

            HStack(spacing: KiezioSpacing.sm) {
                Label(viewModel.persistenceNotice, systemImage: "externaldrive.badge.checkmark")
                if viewModel.queuedReportCount > 0 {
                    Label("\(viewModel.queuedReportCount) Meldungen", systemImage: "flag")
                }
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white.opacity(0.68))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(KiezioSpacing.md)
        .background(KiezioColor.ink, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, KiezioSpacing.md)
        .padding(.top, KiezioSpacing.sm)
    }

    @ViewBuilder
    private var safetyNotice: some View {
        if let event = viewModel.latestSafetyEvent {
            HStack(alignment: .top, spacing: KiezioSpacing.sm) {
                Image(systemName: "shield.lefthalf.filled")
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: KiezioSpacing.xs) {
                    Text(event.title)
                        .font(.subheadline.weight(.semibold))
                    Text(event.detail)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.78))
                }
                Spacer()
            }
            .foregroundStyle(.white)
            .padding(KiezioSpacing.md)
            .background(KiezioColor.teal, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .padding(.horizontal, KiezioSpacing.md)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private var categoryStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: KiezioSpacing.sm) {
                ForEach(PostCategory.allCases) { category in
                    Button {
                        withAnimation(.snappy) {
                            viewModel.selectedCategory = category
                        }
                    } label: {
                        CategoryChip(category: category, isSelected: viewModel.selectedCategory == category)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, KiezioSpacing.md)
        }
    }

    private var sortStrip: some View {
        Picker("Sortierung", selection: $viewModel.selectedSort) {
            ForEach(FeedSort.allCases) { sort in
                Text(sort.rawValue).tag(sort)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, KiezioSpacing.md)
    }

    private var spaceStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: KiezioSpacing.sm) {
                ForEach(viewModel.spaces) { space in
                    Button {
                        withAnimation(.snappy) {
                            viewModel.selectedSpaceID = space.id
                        }
                    } label: {
                        SpaceCardView(
                            space: space,
                            postCount: viewModel.postCount(for: space.id),
                            isSelected: viewModel.selectedSpaceID == space.id
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, KiezioSpacing.md)
        }
    }
}

private struct ReportTarget: Identifiable {
    let id: KiezioPost.ID
}
