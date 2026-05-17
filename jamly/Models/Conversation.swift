//
//  Conversation.swift
//  jamly
//
//  Created by Jonathan Dumesnil on 06/02/2026.
//

/// Configuration de base d'une conversation, utilisée comme bundle d'arguments pour
/// éviter une signature d'init à 5 paramètres positionnels.
///
/// Sert principalement lors de la construction manuelle d'une ``Conversation``
/// (par exemple côté test ou aperçu).
struct ConversationConfig {
    let id: Int
    let isGroup: Bool
    let groupName: String
    let unreadCount: Int
    let memberCount: Int

    init(
        id: Int,
        isGroup: Bool = false,
        groupName: String = "",
        unreadCount: Int = 0,
        memberCount: Int = 0
    ) {
        self.id = id
        self.isGroup = isGroup
        self.groupName = groupName
        self.unreadCount = unreadCount
        self.memberCount = memberCount
    }
}

/// Conversation telle qu'elle apparaît dans la liste des chats (vue inbox).
///
/// Contient les informations légères (dernier message, participants, compteur non-lus)
/// pour l'affichage en cellule. Pour la conversation détaillée avec tous les messages,
/// utiliser ``ConversationDetail``.
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

    /// Retourne le nom à afficher dans la liste des conversations.
    ///
    /// Pour un groupe, retourne le nom du groupe (ou un fallback générique).
    /// Pour une conversation directe, retourne le nom de l'autre participant.
    ///
    /// - Parameter currentUserId: Identifiant de l'utilisateur connecté, utilisé pour
    ///   filtrer son propre profil hors des participants.
    /// - Returns: Le nom à afficher, jamais vide.
    func displayName(currentUserId: Int) -> String {
        if isGroup {
            return groupName ?? "Chat group"
        } else {
            // Pour une conversation directe, on retourne le nom de l'autre participant
            let otherParticipant = participants.first { $0.id != currentUserId }
            return otherParticipant?.username ?? participants.first?.username ?? "Unknown user"
        }
    }

    /// Retourne l'autre participant d'une conversation directe.
    ///
    /// - Parameter currentUserId: Identifiant de l'utilisateur connecté.
    /// - Returns: L'autre participant, ou `nil` si la conversation est un groupe.
    func otherParticipant(currentUserId: Int) -> CommonUser? {
        guard !isGroup else { return nil }
        return participants.first { $0.id != currentUserId }
    }

    /// Retourne l'URL de la photo de profil à afficher dans la cellule.
    ///
    /// - Parameter currentUserId: Identifiant de l'utilisateur connecté.
    /// - Returns: L'URL de la photo de l'autre participant pour une conversation directe,
    ///   ou `nil` pour un groupe (les groupes n'ont pas d'avatar dans cette version).
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

/// Conversation complète avec l'historique de tous ses messages.
///
/// Utilisée dans la vue de détail d'un chat, contrairement à ``Conversation``
/// qui ne contient que le dernier message pour la vue liste.
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

    /// Dernier message de la conversation (le plus récent dans `messages`).
    var lastMessage: Message? {
        messages.last
    }

    /// Nom d'affichage de la conversation : nom du groupe, ou nom du premier participant
    /// pour une conversation directe.
    ///
    /// - Note: Contrairement à ``Conversation/displayName(currentUserId:)``, cette propriété
    ///   ne filtre pas l'utilisateur connecté car la vue détail dispose déjà du contexte.
    var displayName: String {
        if let groupName = groupName {
            return groupName
        }
        // Pour une conversation directe, afficher le nom de l'autre participant
        return participants.first?.username ?? "Chat"
    }
}
