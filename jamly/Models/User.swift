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
    let followed: [FollowedUser]?
    let follower: [FollowedUser]?
    
    enum CodingKeys: String, CodingKey {
        case id, username, email, profilePicture, followed, follower
    }
    
    var followedCount: Int {
        followed?.count ?? 0
    }
    
    var followerCount: Int {
        follower?.count ?? 0
    }
}


struct FollowedUser: Codable, Identifiable {
    let id: Int
    let username: String
}
