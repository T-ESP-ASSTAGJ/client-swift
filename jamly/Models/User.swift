//
//  User.swift
//  jamly
//
//  Created by REVERSS on 07/12/2025.
//

struct User: Codable {
    let id: Int
    let username: String
    let email: String
    let profilePicture: String?
    let phoneNumber: String?
    let bio: String?
    let followingCount: Int
    let followersCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id, username, email, profilePicture, phoneNumber, bio, followingCount, followersCount
    }
}


struct FollowerUser: Codable, Identifiable, Equatable {
    let id: Int
    let username: String
    let profilePicture: String
    
}

struct FollowingUser: Codable, Identifiable {
    let id: Int
    let username: String
    let profilePicture: String
}

struct CommonUser: Codable, Hashable {
    let id: Int
    let username: String
    let profilePicture: String?
}
