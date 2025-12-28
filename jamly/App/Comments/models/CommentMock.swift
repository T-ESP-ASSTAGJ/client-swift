//
//  Comment.swift
//  jamly
//
//  Created by Jonathan Dumesnil on 21/12/2025.
//

import Foundation

struct CommentType: Identifiable, Codable {
    let id: Int
    let user: User
    let content: String
    let createdAt: String
}

// MARK: - Mock Data
extension CommentType {
    static let mockComments: [CommentType] = [
        CommentType(
            id: 1,
            user: User(
                id: 1,
                username: "marie_dubois",
                email: "marie@example.com",
                profilePicture: "https://fastly.picsum.photos/id/237/200/200.jpg?hmac=zHUGikXUDyLCCmvyww1izLK3R3k8oRYBRiTizZEdyfI",
                followed: [],
                follower: []
            ),
            content: "J'adore ce morceau ! 🎵 Il est trop bien !",
            createdAt: "2025-12-21T10:30:00Z"
        ),
        CommentType(
            id: 2,
            user: User(
                id: 2,
                username: "jean_martin",
                email: "jean@example.com",
                profilePicture: "https://fastly.picsum.photos/id/426/200/200.jpg?hmac=5auPuax0L2lXSIX0eJ2Qxa3HzmGUHCrGDPIEMAWgw7o",
                followed: [],
                follower: []
            ),
            content: "Super découverte, merci pour le partage 🔥",
            createdAt: "2025-12-21T09:15:00Z"
        ),
        CommentType(
            id: 3,
            user: User(
                id: 3,
                username: "sophie_l",
                email: "sophie@example.com",
                profilePicture: "https://fastly.picsum.photos/id/64/200/200.jpg?hmac=zAi8hrpKwvMBfY8ypf3mo_XKGAlUOQ3Z7BjzMJQbVBw",
                followed: [],
                follower: []
            ),
            content: "Les paroles sont incroyables, ça me parle vraiment",
            createdAt: "2025-12-21T08:45:00Z"
        ),
        CommentType(
            id: 4,
            user: User(
                id: 4,
                username: "alex_music",
                email: "alex@example.com",
                profilePicture: nil,
                followed: [],
                follower: []
            ),
            content: "En boucle depuis ce matin ! 🎧",
            createdAt: "2025-12-21T07:20:00Z"
        ),
        CommentType(
            id: 5,
            user: User(
                id: 5,
                username: "emma_sound",
                email: "emma@example.com",
                profilePicture: "https://fastly.picsum.photos/id/203/200/200.jpg?hmac=4RqLr1yMCrXPRZZPJhYLFW9qDv8JRQh7H5w6k0vDoQc",
                followed: [],
                follower: []
            ),
            content: "Quelqu'un sait où je peux trouver les accords ?",
            createdAt: "2025-12-20T22:10:00Z"
        )
    ]
}

