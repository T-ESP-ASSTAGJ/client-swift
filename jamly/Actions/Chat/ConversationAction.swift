//
//  ConversationActionswift
//  jamly
//
//  Created by Jonathan Dumesnil on 12/02/2026.
//

/// Chemins des endpoints liés aux conversations, centralisés pour éviter les chaînes magiques
/// dispersées dans les actions.
struct ConversationEndpoint {
    static let conversations = "/conversations"
    static let createConversation = "/conversations"

    static func conversation(_ id: Int) -> String { "/conversations/\(id)" }
    static func deleteConversation(_ id: Int) -> String { "/conversations/\(id)" }
    static func markAsRead(_ id: Int) -> String { "/conversations/\(id)/read"}
}

/// Corps de la requête de création d'une conversation.
struct ConversationRequestResponse: Codable {
    let isGroup: Bool
    let groupName: String?
    /// Identifiants des participants à ajouter, hors utilisateur courant
    /// (le backend l'ajoute automatiquement).
    let participants: [Int]
}

/// Actions API liées aux conversations (inbox, création, lecture, suppression).
enum ConversationAction {
    /// Récupère la liste des conversations de l'utilisateur connecté.
    ///
    /// - Parameter page: Numéro de page pour la pagination. Par défaut `1`.
    /// - Returns: Les conversations renvoyées par le serveur, triées du plus récent au plus ancien.
    /// - Throws: ``APIError`` en cas d'échec.
    static func getConversations(page: Int = 1) async throws -> APIResponse<[Conversation]> {
        let response = try await APIClient.shared.request(
            ConversationEndpoint.conversations,
            method: .get,
            query: ["page": String(page)],
            responseType: [Conversation].self
        )
               
        return response
    }
    
    /// Récupère le détail d'une conversation avec tous ses messages.
    ///
    /// - Parameter conversationId: Identifiant de la conversation.
    /// - Throws: ``APIError`` ; un `404` indique une conversation introuvable ou interdite.
    static func getConversationDetail(conversationId: Int) async throws -> APIResponse<ConversationDetail> {
        let response = try await APIClient.shared.request(
            ConversationEndpoint.conversation(conversationId),
            method: .get,
            responseType: ConversationDetail.self
        )

        
        return response
    }
    
    /// Supprime définitivement une conversation côté serveur.
    ///
    /// - Parameter id: Identifiant de la conversation à supprimer.
    /// - Throws: ``APIError`` en cas d'échec.
    static func deleteConversation(id: Int) async throws -> APIResponse<EmptyResponse> {
        let response = try await APIClient.shared.request(
            ConversationEndpoint.deleteConversation(id),
            method: .delete,
            responseType: EmptyResponse.self
        )
        
        print("✅ Conversation \(id) deleted from server")
        return response
    }
    
    /// Marque tous les messages de la conversation comme lus pour l'utilisateur courant.
    ///
    /// - Parameter id: Identifiant de la conversation.
    /// - Throws: ``APIError`` en cas d'échec.
    static func markAsRead(id: Int) async throws -> APIResponse<EmptyResponse> {
        
        let response = try await APIClient.shared.request(
            ConversationEndpoint.markAsRead(id),
            method: .post,
            responseType: EmptyResponse.self
        )
        
        return response
    }
    
    /// Crée une nouvelle conversation (directe ou de groupe).
    ///
    /// - Parameters:
    ///   - isGroup: `true` pour une conversation de groupe, `false` pour une conversation directe.
    ///   - groupName: Nom du groupe (ignoré pour les conversations directes).
    ///   - participants: Identifiants des autres participants. L'utilisateur courant est ajouté
    ///     automatiquement par le backend.
    /// - Returns: La conversation nouvellement créée.
    /// - Throws: ``APIError`` en cas d'échec.
    static func createConversation(
        isGroup: Bool,
        groupName: String?,
        participants: [Int]
    ) async throws -> APIResponse<Conversation> {
        let response = try await APIClient.shared.request(
            ConversationEndpoint.createConversation,
            method: .post,
            body: ConversationRequestResponse(isGroup: isGroup, groupName: groupName, participants: participants),
            responseType: Conversation.self
        )
        
        return response
    }
}
