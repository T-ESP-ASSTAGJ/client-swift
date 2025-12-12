//
//  PostAction.swift
//  jamly
//
//  Created by REVERSS on 08/12/2025.
//

struct CreatePostRequestResponse: Decodable {
    let id: Int
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
}
