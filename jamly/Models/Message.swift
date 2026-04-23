//
//  Message.swift
//  jamly
//
//  Created by Jonathan Dumesnil on 06/02/2026.
//

import Foundation

// MARK: - Message

struct Message: Codable, Identifiable, Hashable {
    let id: Int
    let author: CommonUser
    let type: String
    let content: String?
    
    // Champs qui peuvent varier selon l'endpoint
    let readAt: String?
    let conversationId: Int?
    let updatedAt: String?
    
    let createdAt: String
    
    // MARK: - Computed Properties

    var isMusicMessage: Bool {
        if type == "track" || type == "music" { return true }
        if type == "share", let content = content,
           content.contains(Config.appleMusicHost), !content.contains(Config.appleMusicPlaylistPath) { return true }
        return false
    }

    var isRead: Bool {
        readAt != nil
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
        
        if let type = type, type == "track" || type == "music" || type == "share" {
            return "🎵 Contenu partagé"
        }
        
        if let content = content {
            return content
        }
        
        return "Message"
    }
}

struct MercureMessageWrapper: Codable {
    let type: String
    let message: Message
}
