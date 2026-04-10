//
//  Conversation.swift
//  jamly
//
//  Created by Jonathan Dumesnil on 06/02/2026.
//

struct ConversationConfig {
    let id: Int
    let isGroup: Bool = false
    let groupName: String = ""
    let unreadCount: Int = 0
    let memberCount: Int = 0
}

struct Conversation: Codable, Identifiable, Hashable {
    let id: Int
    let isGroup: Bool
    let groupName: String?
    let unreadCount: Int
    let memberCount: Int
    let type: String
    let lastMessage: LightMessage?
    let participants: [CommonUser]
    
    enum CodingKeys: String, CodingKey {
        case id, isGroup, groupName, unreadCount, memberCount, type, lastMessage, participants
    }
    
    init(
        config: ConversationConfig,
        type: String = "direct",
        lastMessage: LightMessage? = nil,
        participants: [CommonUser] = []
    ) {
        self.id = config.id
        self.isGroup = config.isGroup
        self.groupName = config.groupName
        self.unreadCount = config.unreadCount
        self.memberCount = config.memberCount
        self.type = type
        self.lastMessage = lastMessage
        self.participants = participants
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id               = try container.decode(Int.self, forKey: .id)
        isGroup          = try container.decodeIfPresent(Bool.self, forKey: .isGroup) ?? false
        groupName        = try container.decodeIfPresent(String.self, forKey: .groupName) ?? ""
        unreadCount      = try container.decodeIfPresent(Int.self, forKey: .unreadCount) ?? 0
        memberCount      = try container.decodeIfPresent(Int.self, forKey: .memberCount) ?? 0
        type             = try container.decodeIfPresent(String.self, forKey: .type) ?? "direct"
        lastMessage      = try container.decodeIfPresent(LightMessage.self, forKey: .lastMessage)
        participants     = try container.decodeIfPresent([CommonUser].self, forKey: .participants) ?? []
    }
    
    // MARK: - Computed Properties
    
    /// Retourne le nom à afficher (groupe ou utilisateur)
    func displayName(currentUserId: Int) -> String {
        if isGroup {
            return groupName ?? "Chat group"
        } else {
            // Pour une conversation directe, on retourne le nom de l'autre participant
            let otherParticipant = participants.first { $0.id != currentUserId }
            return otherParticipant?.username ?? participants.first?.username ?? "Unknown user"
        }
    }
    
    /// Retourne l'autre participant dans une conversation directe
    func otherParticipant(currentUserId: Int) -> CommonUser? {
        guard !isGroup else { return nil }
        return participants.first { $0.id != currentUserId }
    }
    
    /// Retourne l'URL de la photo de profil à afficher
    func displayProfilePicture(currentUserId: Int) -> String? {
        if isGroup {
            // Pour un groupe, pas de photo de profil
            return nil
        } else {
            // Pour une conversation directe, photo de l'autre participant
            return otherParticipant(currentUserId: currentUserId)?.profilePicture
        }
    }
}

// MARK: - ConversationDetail

/// Représente une conversation complète avec tous ses messages
struct ConversationDetail: Codable, Identifiable {
    let id: Int
    let isGroup: Bool
    let groupName: String?
    let messages: [Message]
    let createdAt: String
    let updatedAt: String
    let memberCount: Int
    let participants: [CommonUser]
    
    enum CodingKeys: String, CodingKey {
        case id, isGroup, groupName, messages, createdAt, updatedAt, memberCount, participants
    }
    
    /// Dernier message de la conversation
    var lastMessage: Message? {
        messages.last
    }
    
    /// Nom d'affichage de la conversation
    var displayName: String {
        if let groupName = groupName {
            return groupName
        }
        // Pour une conversation directe, afficher le nom de l'autre participant
        return participants.first?.username ?? "Chat"
    }
}
