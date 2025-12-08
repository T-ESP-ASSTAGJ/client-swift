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
    
    enum CodingKeys: String, CodingKey {
        case id, username, email, profilePicture
    }
}
