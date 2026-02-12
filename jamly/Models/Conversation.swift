//
//  Conversation.swift
//  jamly
//
//  Created by Jonathan Dumesnil on 06/02/2026.
//

struct Conversation: Codable, Identifiable {
    let id: Int
    let isGroup: Bool
    let groupName: String?
    let unreadCount: Int
    let memberCount: Int
    let type: String
    let lastMessage: [String]
    let participantsInfo: [[String]]
    
    enum CodingKeys: String, CodingKey {
        case id, isGroup, groupName, unreadCount, memberCount, type, lastMessage, participantsInfo
    }
    
    // MARK: - Computed Properties
    
    var displayName: String {
        if isGroup {
            return groupName ?? "Groupe"
        } else {
            // Pour une conversation 1-1, prendre le nom du premier participant
            return participantsInfo.first?.first ?? "Inconnu"
        }
    }
    
    var profilePicture: String? {
        if isGroup {
            return nil
        } else {
            // Pour une conversation 1-1, prendre l'avatar du premier participant
            guard let participant = participantsInfo.first, participant.count > 1 else {
                return nil
            }
            let picture = participant[1]
            return picture.isEmpty ? nil : picture
        }
    }
}
