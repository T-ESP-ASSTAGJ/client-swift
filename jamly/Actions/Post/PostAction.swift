//
//  PostAction.swift
//  jamly
//
//  Created by REVERSS on 08/12/2025.
//

struct CreatePostRequestResponse: Decodable {
    let id: Int
}

struct LikePostBody: Encodable {
    let entityClass: String = "App\\Entity\\Post"
    let entityId: Int
}

enum PostActions {
    static func create(post: CreatePost) async throws -> APIResponse<CreatePostRequestResponse> {
        let response = try await APIClient.shared.request(
            "/posts",
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
            "/likes",
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
            "/likes/delete",
            method: .post,
            body: body,
            responseType: EmptyResponse.self
        )
        
        print("❤️ Post \(post.id) Unliked!")
        
        return response
    }
}
