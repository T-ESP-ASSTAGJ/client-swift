//
//  FollowerAction.swift
//  jamly
//
//  Created by Jonathan Dumesnil on 29/12/2025.
//

enum FollowingAction {
    static func getFollowingUsers(page: Int = 1, userId: Int) async throws -> APIResponse<[FollowingUser]> {
        let response = try await APIClient.shared.request(
            "/users/\(userId)/following",
            method: .get,
            responseType: [FollowingUser].self
        )
        
        return response
    }
}
