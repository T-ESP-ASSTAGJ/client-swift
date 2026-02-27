//
//  FollowerAction.swift
//  jamly
//
//  Created by Jonathan Dumesnil on 29/12/2025.
//


enum FollowerAction {
    // TODO pagination
    static func getFollowerUsers(userId: Int, page: Int = 1) async throws -> APIResponse<[FollowerUser]> {
        let response = try await APIClient.shared.request(
            "/users/\(userId)/followers",
            method: .get,
            query: ["page": String(1)],
            responseType: [FollowerUser].self
        )
        
        return response
    }
}
