//
//  User.swift
//  jamly
//
//  Created by REVERSS on 06/12/2025.
//


// Actions/UserActions.swift
import Foundation

// MARK: - Endpoints
struct UserEndpoints {
    // Base paths
    static let me = "/users/me"
    static let users = "/users"
    static let posts = "/posts"
    
    // Helpers to build parameterized paths
    static func user(_ id: Int) -> String { "/users/\(id)" }
    static func follow(_ id: Int) -> String { "/users/\(id)/follow" }
    static func unfollow(_ id: Int) -> String { "/users/\(id)/unfollow" }
    static func likes(_ id: Int) -> String { "/users/\(id)/likes" }
}


enum UserActions {
    static func fetchMe() async throws -> APIResponse<User> {
        let response = try await APIClient.shared.request(
            UserEndpoints.me,
            method: .get,
            responseType: User.self
        )
        
        print("😁 /ME \(response.value)")
        
        return response
    }
    
    static func getUserById(userId: Int) async throws -> APIResponse<User> {
        let response = try await APIClient.shared.request(
            UserEndpoints.user(userId),
            method: .get,
            responseType: User.self
        )
        
        print("👤 Fetched user \(userId): \(response.value.username)")
        
        return response
    }
    
    static func followUser(userId: Int) async throws -> APIResponse<EmptyResponse> {
        let response = try await APIClient.shared.request(
            UserEndpoints.follow(userId),
            method: .post,
            responseType: EmptyResponse.self
        )
        
        print("✅ Followed user \(userId)")
        
        return response
    }
    
    static func unfollowUser(userId: Int) async throws -> APIResponse<EmptyResponse> {
        let response = try await APIClient.shared.request(
            UserEndpoints.unfollow(userId),
            method: .delete,
            responseType: EmptyResponse.self
        )
        
        print("❌ Unfollowed user \(userId)")
        
        return response
    }
    
    static func getLikedPostsByUser(userId: Int, page: Int = 1) async throws -> APIResponse<[Post]> {
        let response = try await APIClient.shared.request(
            UserEndpoints.likes(userId),
            method: .get,
            query: ["page": String(page)],
            responseType: [Post].self
        )
        
        return response
    }
    
    static func getPostsByUser(userId: Int, page: Int = 1) async throws -> APIResponse<[Post]> {
        let response = try await APIClient.shared.request(
            UserEndpoints.posts,
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
            UserEndpoints.me,
            method: .patch,
            body: body,
            responseType: User.self
        )
        
        return response
    }
    
    static func deleteAccount(userId: Int) async throws -> APIResponse<EmptyResponse> {
        let response = try await APIClient.shared.request(
            UserEndpoints.user(userId),
            method: .delete,
            responseType: EmptyResponse.self
        )
        
        return response
    }
}
