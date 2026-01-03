//
//  FollowerAction.swift
//  jamly
//
//  Created by Jonathan Dumesnil on 29/12/2025.
//


enum FollowerAction {
    // TODO pagination
    static func getFollowerUsers(userId: Int) async throws -> APIResponse<[FollowerUser]> {
        let response = try await APIClient.shared.request(
            "/users/\(userId)/followers",
            method: .get,
            responseType: [FollowerUser].self
        )
        
        return response
    }
}
