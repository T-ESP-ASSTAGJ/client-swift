//
//  Message.swift
//  jamly
//
//  Created by Jonathan Dumesnil on 06/02/2026.
//

import Foundation

struct Message: Codable, Identifiable {
    let id: Int
    let author: Author
    let type: String
    let content: String?
    let trackMetaData: [String]?
    let memberCount: Int
    let isRead: Bool
    let readAt: String
    let conversationId: Int
    
    enum CodingKeys: String, CodingKey {
        case id, author, type, content, trackMetaData, memberCount, isRead, readAt, conversationId
    }
    
    // MARK: - Computed Properties
    
    var isMusicMessage: Bool {
        type == "track" || type == "music"
    }
    
    var trackTitle: String? {
        guard isMusicMessage, let metadata = trackMetaData, metadata.count > 0 else {
            return nil
        }
        return metadata[0]
    }
    
    var trackArtist: String? {
        guard isMusicMessage, let metadata = trackMetaData, metadata.count > 1 else {
            return nil
        }
        return metadata[1]
    }
    
    var trackImageUrl: String? {
        guard isMusicMessage, let metadata = trackMetaData, metadata.count > 2 else {
            return nil
        }
        return metadata[2]
    }
    
    var timeString: String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: readAt) else {
            return ""
        }
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        return timeFormatter.string(from: date)
    }
    
    func isFromCurrentUser(currentUserId: Int) -> Bool {
        author.id == currentUserId
    }
}

struct Author: Codable, Hashable {
    let id: Int
    let username: String
    let profile_picture: String?
}

struct AuthorForLightMessage: Codable, Hashable {
    let id: Int
    let username: String
}

struct LightMessage: Codable, Identifiable, Hashable {
    let id: Int
    let type: String
    let content: String?
    let preview: String
    let author: AuthorForLightMessage
    let created_at: String
}
