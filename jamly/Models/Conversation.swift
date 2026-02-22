//
//  Conversation.swift
//  jamly
//
//  Created by Jonathan Dumesnil on 06/02/2026.
//

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
        id: Int,
        isGroup: Bool = false,
        groupName: String = "",
        unreadCount: Int = 0,
        memberCount: Int = 0,
        type: String = "direct",
        lastMessage: LightMessage? = nil,
        participants: [CommonUser] = []
    ) {
        self.id = id
        self.isGroup = isGroup
        self.groupName = groupName
        self.unreadCount = unreadCount
        self.memberCount = memberCount
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
    var displayName: String {
        if isGroup {
            return groupName ?? "Chat group"
        } else {
            // Pour une conversation directe, on retourne le nom de l'autre participant
            return participants.first?.username ?? "Unknown user"
        }
    }
    
    /// Retourne l'URL de la photo de profil à afficher
    var displayProfilePicture: String? {
        if isGroup {
            // Pour un groupe, pas de photo de profil
            return nil
        } else {
            // Pour une conversation directe, photo de l'autre participant
            return participants.first?.profilePicture
        }
    }
}
