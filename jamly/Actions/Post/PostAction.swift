//
//  PostAction.swift
//  jamly
//
//  Created by REVERSS on 08/12/2025.
//

struct CreatePostRequestResponse: Decodable {
    let id: Int
}

struct CreateReportResponse: Decodable {
    let id: Int
}

struct LikePostBody: Encodable {
    let entityClass: String = "App\\Entity\\Post"
    let entityId: Int
}

struct PostEndpoint {
    static let posts = "/posts"
    static func viewPost(_ postId: Int) -> String { "/posts/\(postId)/view" }
}

struct LikeEndpoint {
    static let likes = "/likes"
    static let deleteLike = "/likes/delete"
}

struct ReportEndpoint {
    static let report = "/reports"
    static let reportReasons = "/reports-reasons"
}

enum PostActions {
    static func fetchPost(id: Int) async throws -> APIResponse<Post> {
        let response = try await APIClient.shared.request(
            "/posts/\(id)",
            method: .get,
            responseType: Post.self
        )
        
        return response
    }
    
    static func create(post: CreatePostRequest) async throws -> APIResponse<CreatePostRequestResponse> {
        let response = try await APIClient.shared.request(
            PostEndpoint.posts,
            method: .post,
            body: post,
            responseType: CreatePostRequestResponse.self
        )
        
        print(response)
        
        return response
    }
    
    static func likePost(post: Post) async throws -> APIResponse<EmptyResponse> {
        let body = LikePostBody(entityId: post.id)
        
        let response = try await APIClient.shared.request(
            LikeEndpoint.likes,
            method: .post,
            body: body,
            responseType: EmptyResponse.self
        )
        
        print("❤️ Post \(post.id) Liked!")
        
        return response
    }
    
    static func unlikePost(post: Post) async throws -> APIResponse<EmptyResponse> {
        let body = LikePostBody(entityId: post.id)
        
        let response = try await APIClient.shared.request(
            LikeEndpoint.deleteLike,
            method: .post,
            body: body,
            responseType: EmptyResponse.self
        )
        
        print("❤️ Post \(post.id) Unliked!")
        
        return response
    }
    
    static func viewPost(post: Post) async throws -> APIResponse<EmptyResponse> {
        let postId = post.id

        let response = try await APIClient.shared.request(
            PostEndpoint.viewPost(postId),
            method: .patch,
            responseType: EmptyResponse.self
        )

        return response
    }

    static func fetchReportReasons() async throws -> APIResponse<[ReportReason]> {
        let response = try await APIClient.shared.request(
            ReportEndpoint.reportReasons,
            method: .get,
            responseType: [ReportReason].self
        )
        return response
    }

    static func reportPost(postId: Int, reason: String, message: String) async throws -> APIResponse<EmptyResponse> {
        let body = ReportBody(entityId: postId, reason: reason, message: message)
        let response = try await APIClient.shared.request(
            ReportEndpoint.report,
            method: .post,
            body: body,
            responseType: EmptyResponse.self
        )
        return response
    }
}
