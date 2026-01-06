//
//  Post.swift
//  jamly
//
//  Created by REVERSS on 08/12/2025.
//

struct CreatePost: Codable {
    let caption: String?
    let songId: Int
    let frontPhoto: String
    let backPhoto: String
    let location: String
}

struct Post: Codable, Identifiable {
    let id: Int
    let user: User
    let caption: String
    let track: Track
    let frontImage: String
    let backImage: String
    let location: String
    let likesCount: Int
    let commentsCount: Int
    let isLiked: Bool
    // let createdAt: String
    
    struct User: Codable {
        let id: Int
        let username: String
        let profilePicture: String
    }
    
    struct Track: Codable {
        let id: Int
        let title: String
        let artistName: String
    }
}
