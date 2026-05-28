import Foundation

protocol PostService {
    func fetchPosts() async -> [KiezioPost]
    func createPost(text: String, category: PostCategory, spaceID: KiezioSpace.ID, reach: ReachLevel, trust: LocalUserTrust) async -> KiezioPost
}

struct MockPostService: PostService {
    func fetchPosts() async -> [KiezioPost] {
        MockPosts.make()
    }

    func createPost(text: String, category: PostCategory, spaceID: KiezioSpace.ID, reach: ReachLevel, trust: LocalUserTrust) async -> KiezioPost {
        KiezioPost(
            id: UUID(),
            authorID: "current-user",
            authorDisplayName: "Du im Kiez",
            spaceID: spaceID,
            text: text.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            reach: reach,
            createdAt: Date(),
            reactions: 0,
            replies: [],
            qualityScore: max(0.45, trust.score),
            authorTrust: trust.score,
            reportCount: 0,
            moderationStatus: .visible,
            removalReason: nil,
            hasCurrentUserReacted: false
        )
    }
}
