//
//  User.swift
//  jamly
//
//  Created by REVERSS on 06/12/2025.
//


// Actions/UserActions.swift
import Foundation

enum UserActions {
    static func fetchMe() async throws -> APIResponse<User> {
        let response = try await APIClient.shared.request(
            "/users/me",
            method: .get,
            responseType: User.self
        )
        
        print("😁 /ME \(response.value)")
        
        return response
    }
    
    static func followUser(userId: Int) async throws -> APIResponse<EmptyResponse> {
        let response = try await APIClient.shared.request(
            "/users/\(userId)/follow",
            method: .post,
            responseType: EmptyResponse.self
        )
        
        print("✅ Followed user \(userId)")
        
        return response
    }
    
    static func unfollowUser(userId: Int) async throws -> APIResponse<EmptyResponse> {
        let response = try await APIClient.shared.request(
            "/users/\(userId)/unfollow",
            method: .delete,
            responseType: EmptyResponse.self
        )
        
        print("❌ Unfollowed user \(userId)")
        
        return response
    }
}
