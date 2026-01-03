//
//  FollowerAction.swift
//  jamly
//
//  Created by Jonathan Dumesnil on 29/12/2025.
//

enum FollowingAction {
    // TODO pagination
    static func getFollowingUsers(userId: Int) async throws -> APIResponse<[FollowingUser]> {
        let response = try await APIClient.shared.request(
            "/users/\(userId)/following",
            method: .get,
            responseType: [FollowingUser].self
        )
        
        return response
    }
}
