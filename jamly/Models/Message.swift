//
//  Message.swift
//  jamly
//
//  Created by Jonathan Dumesnil on 06/02/2026.
//

import Foundation

// MARK: - Track Metadata (optionnel, pour les messages créés)

struct TrackMetadata: Codable, Hashable {
    let title: String?
    let artist: String?
    let album: String?
    let imageUrl: String?
    let duration: Int?
}

// MARK: - Message

struct Message: Codable, Identifiable, Hashable {
    let id: Int
    let author: CommonUser
    let type: String
    let content: String?
    
    // Champs qui peuvent varier selon l'endpoint
    let track: String?
    let trackMetadata: TrackMetadata?
    let readAt: String?
    let conversationId: Int?
    let updatedAt: String?
    
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, author, type, content, track, trackMetadata, readAt, conversationId, updatedAt, createdAt
    }
    
    // MARK: - Computed Properties
    
    var isMusicMessage: Bool {
        type == "track" || type == "music"
    }
    
    var isRead: Bool {
        readAt != nil
    }
    
    var trackTitle: String? {
        trackMetadata?.title
    }
    
    var trackArtist: String? {
        trackMetadata?.artist
    }
    
    var trackImageUrl: String? {
        trackMetadata?.imageUrl
    }
    
    /// Convertit la date ISO8601 en Date
    var createdDate: Date {
        ISO8601DateFormatter().date(from: createdAt) ?? Date()
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: createdDate)
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "d MMM 'à' HH:mm"
        return formatter.string(from: createdDate)
    }
    
    func isFromCurrentUser(currentUserId: Int) -> Bool {
        author.id == currentUserId
    }
}

// MARK: - Light Message (pour la liste des conversations)

struct LightMessage: Codable, Identifiable, Hashable {
    let id: Int
    let preview: String?
    let author: CommonUser
    let createdAt: String
    let type: String?
    let content: String?
    
    /// Retourne un aperçu du message
    var displayPreview: String {
        if let preview = preview {
            return preview
        }
        
        if let type = type, type == "track" || type == "music" {
            return "🎵 Piste partagée"
        }
        
        if let content = content {
            return content
        }
        
        return "Message"
    }
}

