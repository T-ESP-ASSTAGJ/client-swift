//
//  CommentAction.swift
//  jamly
//
//  Created by Jonathan Dumesnil on 29/12/2025.
//

struct CreateCommentRequest: Encodable {
    let content: String
}

enum CommentAction {
    static func CreateComment(postId: Int, content: String) async throws -> APIResponse<CommentResponse> {
        let requestBody = CreateCommentRequest(content: content)

        let response = try await APIClient.shared.request(
            "/posts/\(postId)/comments",
            method: .post,
            body: requestBody,
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
}
