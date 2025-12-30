//
//  SearchModels.swift
//  jamly
//
//  Created by Alexandre Vandenbulcke on 30/12/2025.
//

import Foundation

// User search result model
struct SearchUser: Codable, Identifiable {
    let id: Int
    let username: String
    let email: String?
    let profilePicture: String?
    
    enum CodingKeys: String, CodingKey {
        case id, username, email, profilePicture
    }
}

// Paginated response wrapper
struct PaginatedResponse<T: Codable>: Codable {
    let data: [T]
    let page: Int
    let totalPages: Int
    let totalItems: Int
    let hasMore: Bool
    
    enum CodingKeys: String, CodingKey {
        case data, page, totalPages, totalItems, hasMore
    }
}

// If your API returns data directly as an array, use this:
struct SearchUsersResponse: Codable {
    let users: [SearchUser]
    
    // If the API returns users directly without a wrapper,
    // you can use init(from decoder:) to handle it
    init(from decoder: Decoder) throws {
        // Try to decode as array directly
        if let container = try? decoder.singleValueContainer(),
           let users = try? container.decode([SearchUser].self) {
            self.users = users
        } else {
            // Or try to decode with "users" key
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.users = try container.decode([SearchUser].self, forKey: .users)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case users
    }
}
