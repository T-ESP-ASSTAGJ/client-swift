//
//  Comment.swift
//  jamly
//
//  Created by Jonathan Dumesnil on 29/12/2025.
//

struct CommentResponse: Codable, Identifiable {
    let id: Int
    let user: CommonUser
    let content: String
    let likesCount: Int
    let isLiked: Bool
    let createdAt: String?
}

struct SendCommentResponse: Codable {
    let id: Int
    let user: CommonUser
    let content: String
}
