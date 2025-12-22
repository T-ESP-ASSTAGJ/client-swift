//
//  PostAction.swift
//  jamly
//
//  Created by REVERSS on 08/12/2025.
//

struct FeedRequestResponse: Decodable {
    let feed: [Post]
}

enum FeedAction{
    static func getPublicFeed(page: Int = 1) async throws -> APIResponse<FeedRequestResponse> {
        let response = try await APIClient.shared.request(
            "/feed/public?\(page)",
            method: .get,
            responseType: FeedRequestResponse.self
        )
        
        print(response)
        
        return response
    }
    
    static func getPrivateFeed(page: Int = 1) async throws -> APIResponse<FeedRequestResponse> {
        let response = try await APIClient.shared.request(
            "/feed/private?\(page)",
            method: .get,
            responseType: FeedRequestResponse.self
        )
        
        print(response)
        
        return response
    }
}
