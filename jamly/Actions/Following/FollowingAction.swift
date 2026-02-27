//
//  FollowerAction.swift
//  jamly
//
//  Created by Jonathan Dumesnil on 29/12/2025.
//

enum FollowingAction {
    // TODO pagination
    static func getFollowingUsers(userId: Int, page: Int = 1) async throws -> APIResponse<[FollowingUser]> {
        let response = try await APIClient.shared.request(
            "/users/\(userId)/following",
            method: .get,
            query: ["page": String(page)],
            responseType: [FollowingUser].self
        )
        
        return response
    }
}
