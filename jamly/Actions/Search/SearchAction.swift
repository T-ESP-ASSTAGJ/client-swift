//
//  SearchAction.swift
//  jamly
//
//  Created by Alexandre Vandenbulcke on 30/12/2025.
//

import Foundation

enum SearchAction {
    /// Search for users by username with pagination
    /// - Parameters:
    ///   - username: The search query
    ///   - page: The page number (starts at 1)
    /// - Returns: Array of SearchUser objects
    static func searchUsers(username: String, page: Int = 1) async throws -> APIResponse<[SearchUser]> {
        let response = try await APIClient.shared.request(
            "/users",
            method: .get,
            query: [
                "username": username,
                "page": String(page)
            ],
            responseType: [SearchUser].self
        )
        
        print("🔍 Search results for '\(username)' (page \(page)): \(response.value.count) users found")
        
        return response
    }
}
