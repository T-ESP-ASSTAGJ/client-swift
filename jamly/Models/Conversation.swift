//
//  Conversation.swift
//  jamly
//
//  Created by Jonathan Dumesnil on 06/02/2026.
//

struct Conversation: Codable, Identifiable, Hashable {
    let id: Int
    let groupName: String
    let unreadCount: Int
    let memberCount: Int
    let type: String
    let lastMessage: LightMessage?
    let participantsInfo: [Author]
    
    enum CodingKeys: String, CodingKey {
        case id, groupName, unreadCount, memberCount, type, lastMessage, participantsInfo
    }
    
    init(
        id: Int,
        groupName: String = "",
        unreadCount: Int = 0,
        memberCount: Int = 0,
        type: String = "direct",
        lastMessage: LightMessage? = nil,
        participantsInfo: [Author] = []
    ) {
        self.id = id
        self.groupName = groupName
        self.unreadCount = unreadCount
        self.memberCount = memberCount
        self.type = type
        self.lastMessage = lastMessage
        self.participantsInfo = participantsInfo
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id               = try container.decode(Int.self, forKey: .id)
        groupName        = try container.decodeIfPresent(String.self, forKey: .groupName) ?? ""
        unreadCount      = try container.decodeIfPresent(Int.self, forKey: .unreadCount) ?? 0
        memberCount      = try container.decodeIfPresent(Int.self, forKey: .memberCount) ?? 0
        type             = try container.decodeIfPresent(String.self, forKey: .type) ?? "direct"
        lastMessage      = try container.decodeIfPresent(LightMessage.self, forKey: .lastMessage)
        participantsInfo = try container.decodeIfPresent([Author].self, forKey: .participantsInfo) ?? []
    }
    
    // MARK: - Computed Properties
    
    /// Indique si c'est une conversation de groupe
    var isGroup: Bool {
        type == "group"
    }
    
    /// Retourne le nom à afficher (groupe ou utilisateur)
    var displayName: String {
        if isGroup {
            return groupName
        } else {
            // Pour une conversation directe, on retourne le nom de l'autre participant
            return participantsInfo.first?.username ?? groupName
        }
    }
    
    /// Retourne l'URL de la photo de profil à afficher
    var displayProfilePicture: String? {
        if isGroup {
            // Pour un groupe, pas de photo de profil
            return nil
        } else {
            // Pour une conversation directe, photo de l'autre participant
            return participantsInfo.first?.profilePicture
        }
    }
}
