//
//  PostAction.swift
//  jamly
//
//  Created by REVERSS on 08/12/2025.
//

enum FeedAction{
    static func getPublicFeed(page: Int = 1) async throws -> APIResponse<[Post]> {
        let response = try await APIClient.shared.request(
            "/feed/public",
            method: .get,
            responseType: [Post].self
        )
        
        return response
    }
    
    static func getPrivateFeed(page: Int = 1) async throws -> APIResponse<[Post]> {
        let response = try await APIClient.shared.request(
            "/feed/private",
            method: .get,
            responseType: [Post].self
        )
        
        return response
    }
}
