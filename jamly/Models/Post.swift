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

struct Post: Codable {
    let id: Int
    let user: User
    let caption: String
    let track: Track
    let photoUrl: String
    let location: String
    // let createdAt: String
    
    struct User: Codable {
        let id: Int
        let username: String
        let profilePicture: String
    }
    
    struct Track: Codable {
        let id: Int
        let title: String
        let coverUrl: String
        let metadata: Metadata
        let artist: Artist
        
        struct Metadata: Codable {
            let duration: Int
            let genre: String
        }
        
        struct Artist: Codable {
            let id: Int
            let name: String
        }
    }
}
