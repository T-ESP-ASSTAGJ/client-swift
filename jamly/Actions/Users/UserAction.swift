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
    
    static func getUserById(userId: Int) async throws -> APIResponse<User> {
        let response = try await APIClient.shared.request(
            "/users/\(userId)",
            method: .get,
            responseType: User.self
        )
        
        print("👤 Fetched user \(userId): \(response.value.username)")
        
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
    
    static func getLikedPostsByUser(userId: Int, page: Int = 1) async throws -> APIResponse<[Post]> {
        let response = try await APIClient.shared.request(
            "/users/\(userId)/likes",
            method: .get,
            query: ["page": String(page)],
            responseType: [Post].self
        )
        
        return response
    }
    
    static func getPostsByUser(userId: Int, page: Int = 1) async throws -> APIResponse<[Post]> {
        let response = try await APIClient.shared.request(
            "/posts",
            method: .get,
            query: ["user": "\(userId)", "page": String(page)],
            responseType: [Post].self
        )
        
        print("📝 Found \(response.value.count) posts of user \(userId)")
        
        return response
    }
    
    static func updateProfile(username: String?, phoneNumber: String?, bio: String?, profilePicture: String?) async throws -> APIResponse<User> {
        struct UpdateProfileRequest: Codable {
            let username: String?
            let phoneNumber: String?
            let bio: String?
            let profilePicture: String?
        }
        
        let body = UpdateProfileRequest(
            username: username,
            phoneNumber: phoneNumber,
            bio: bio,
            profilePicture: profilePicture
        )
        
        let response = try await APIClient.shared.request(
            "/users/me",
            method: .patch,
            body: body,
            responseType: User.self
        )
        
        return response
    }
    
    static func deleteAccount(userId: Int) async throws -> APIResponse<EmptyResponse> {
        let response = try await APIClient.shared.request(
            "/users/\(userId)",
            method: .delete,
            responseType: EmptyResponse.self
        )
        
        return response
    }
}
