import Foundation

protocol CommunityBackendService {
    func fetchBackendPosts() async throws -> [KiezioPost]
    func createBackendPost(text: String, category: PostCategory, spaceID: KiezioSpace.ID, reach: ReachLevel, trust: LocalUserTrust) async throws -> KiezioPost
    func toggleReaction(postID: KiezioPost.ID) async throws -> KiezioPost
    func addReply(postID: KiezioPost.ID, text: String) async throws -> KiezioPost
    func toggleReplyReaction(postID: KiezioPost.ID, replyID: PostReply.ID) async throws -> KiezioPost
    func report(targetKind: ReportTargetKind, targetID: UUID, parentPostID: UUID?, reason: ReportReason) async throws -> ReportRecord
    func setControl(kind: BackendControlKind, targetID: String) async throws
    func exportUserData() async throws -> String
    func deleteAccount() async throws
}

enum BackendControlKind: String, Codable {
    case hide
    case mute
    case block
}

struct BackendAPIService: PostService, CommunityBackendService {
    private let client: BackendClient
    private let fallback = MockPostService()

    init(client: BackendClient = BackendClient()) {
        self.client = client
    }

    func fetchPosts() async -> [KiezioPost] {
        do {
            return try await fetchBackendPosts()
        } catch {
            return await fallback.fetchPosts()
        }
    }

    func createPost(text: String, category: PostCategory, spaceID: KiezioSpace.ID, reach: ReachLevel, trust: LocalUserTrust) async -> KiezioPost {
        do {
            return try await createBackendPost(text: text, category: category, spaceID: spaceID, reach: reach, trust: trust)
        } catch {
            return await fallback.createPost(text: text, category: category, spaceID: spaceID, reach: reach, trust: trust)
        }
    }

    func fetchBackendPosts() async throws -> [KiezioPost] {
        try await client.request(path: "/posts", method: "GET", body: Optional<EmptyRequest>.none, response: [KiezioPost].self)
    }

    func createBackendPost(text: String, category: PostCategory, spaceID: KiezioSpace.ID, reach: ReachLevel, trust: LocalUserTrust) async throws -> KiezioPost {
        try await client.request(
            path: "/posts",
            method: "POST",
            body: CreatePostRequest(text: text, category: category, spaceID: spaceID, reach: reach),
            response: KiezioPost.self
        )
    }

    func toggleReaction(postID: KiezioPost.ID) async throws -> KiezioPost {
        try await client.request(path: "/posts/\(postID.uuidString)/reactions", method: "POST", body: Optional<EmptyRequest>.none, response: KiezioPost.self)
    }

    func addReply(postID: KiezioPost.ID, text: String) async throws -> KiezioPost {
        try await client.request(path: "/posts/\(postID.uuidString)/replies", method: "POST", body: ReplyRequest(text: text), response: KiezioPost.self)
    }

    func toggleReplyReaction(postID: KiezioPost.ID, replyID: PostReply.ID) async throws -> KiezioPost {
        try await client.request(
            path: "/posts/\(postID.uuidString)/replies/\(replyID.uuidString)/reactions",
            method: "POST",
            body: Optional<EmptyRequest>.none,
            response: KiezioPost.self
        )
    }

    func report(targetKind: ReportTargetKind, targetID: UUID, parentPostID: UUID?, reason: ReportReason) async throws -> ReportRecord {
        try await client.request(
            path: "/reports",
            method: "POST",
            body: ReportRequest(targetKind: targetKind, targetID: targetID, parentPostID: parentPostID, reason: reason),
            response: ReportRecord.self
        )
    }

    func setControl(kind: BackendControlKind, targetID: String) async throws {
        _ = try await client.request(path: "/controls", method: "POST", body: ControlRequest(kind: kind, targetID: targetID), response: BackendControlResponse.self)
    }

    func exportUserData() async throws -> String {
        try await client.requestRaw(path: "/me/export", method: "GET", body: Optional<EmptyRequest>.none)
    }

    func deleteAccount() async throws {
        _ = try await client.request(path: "/me", method: "DELETE", body: Optional<EmptyRequest>.none, response: DeleteAccountResponse.self)
    }
}

struct BackendClient {
    var baseURL: URL = AppConfiguration.apiBaseURL
    var userID: String?

    func request<Body: Encodable, Response: Decodable>(
        path: String,
        method: String,
        body: Body?,
        response: Response.Type
    ) async throws -> Response {
        let data = try await requestData(path: path, method: method, body: body)
        return try decoder.decode(Response.self, from: data)
    }

    func requestRaw<Body: Encodable>(path: String, method: String, body: Body?) async throws -> String {
        let data = try await requestData(path: path, method: method, body: body)
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    private func requestData<Body: Encodable>(path: String, method: String, body: Body?) async throws -> Data {
        let url = baseURL.appending(path: path)
        var request = URLRequest(url: url, timeoutInterval: 2.5)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(userID ?? AppConfiguration.apiUserID, forHTTPHeaderField: "X-Kiezio-User-ID")

        if let body {
            request.httpBody = try encoder.encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw BackendError.badResponse
        }
        return data
    }

    private var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

enum BackendError: Error {
    case badResponse
}

private struct EmptyRequest: Encodable {}

private struct CreatePostRequest: Encodable {
    var text: String
    var category: PostCategory
    var spaceID: KiezioSpace.ID
    var reach: ReachLevel
}

private struct ReplyRequest: Encodable {
    var text: String
}

private struct ReportRequest: Encodable {
    var targetKind: ReportTargetKind
    var targetID: UUID
    var parentPostID: UUID?
    var reason: ReportReason
}

private struct ControlRequest: Encodable {
    var kind: BackendControlKind
    var targetID: String
}

private struct BackendControlResponse: Decodable {
    var kind: BackendControlKind
    var targetID: String
}

private struct DeleteAccountResponse: Decodable {
    var deleted: Bool
}
