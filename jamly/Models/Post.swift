//
//  Post.swift
//  jamly
//
//  Created by REVERSS on 08/12/2025.
//

struct CreatePost: Codable {
    let songPreview: String
    let caption: String?
    let trackId: Int
    let photoUrl: String
    let location: String
}
