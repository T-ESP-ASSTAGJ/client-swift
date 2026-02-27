//
//  Post.swift
//  jamly
//
//  Created by REVERSS on 08/12/2025.
//

struct CreatePostRequest: Codable {
    let caption: String
    let songId: String
    let trackTitle: String
    let artistName: String
    let releaseYear: Int
    let frontImage: String
    let backImage: String
    let coverImage: String
    let location: String
}

struct Post: Codable, Identifiable, Hashable {
    let id: Int
    let user: User
    let caption: String
    let track: Track
    let frontImage: String
    let backImage: String
    let location: String
    let commentsCount: Int
    let likesCount: Int
    let isLiked: Bool
    let createdAt: String
    
    struct User: Codable {
        let id: Int
        let username: String
        let profilePicture: String
        let createdAt: String
    }
    
    struct Track: Codable {
        let id: Int
        let songId: String
        let title: String
        let artistName: String
        let coverImage: String
        let releaseYear: Int
        let createdAt: String
    }
    
    // Hashable & Equatable conformance based on stable identifier
    static func == (lhs: Post, rhs: Post) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
