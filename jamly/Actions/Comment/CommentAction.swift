//
//  CommentAction.swift
//  jamly
//
//  Created by Jonathan Dumesnil on 29/12/2025.
//

struct CreateCommentRequest: Encodable {
    let content: String
}

struct LikeCommentRequest: Encodable {
    let entityClass: String = "App\\Entity\\Comment"
    let entityId: Int
}
enum CommentAction {
    static func CreateComment(postId: Int, content: String) async throws -> APIResponse<CommentResponse> {
        let response = try await APIClient.shared.request(
            "/posts/\(postId)/comments",
            method: .post,
            body: CreateCommentRequest(content: content),
            responseType: CommentResponse.self
        )
        
        return response
    }
    
    static func getComments(postId: Int) async throws -> APIResponse<[CommentResponse]> {
        let response = try await APIClient.shared.request(
            "/posts/\(postId)/comments",
            method: .get,
            responseType: [CommentResponse].self
        )
        
        return response
    }
    
    static func like(commentId: Int) async throws -> APIResponse<EmptyResponse> {
        let response = try await APIClient.shared.request(
            "/likes",
            method: .post,
            body : LikeCommentRequest(entityId: commentId),
            responseType: EmptyResponse.self
        )
        
        return response
    }
    
    static func unlike(commentId: Int) async throws -> APIResponse<EmptyResponse> {
        let response = try await APIClient.shared.request(
            "/likes/\(commentId)",
            method: .delete,
            responseType: EmptyResponse.self
        )
        
        return response
    }
}
