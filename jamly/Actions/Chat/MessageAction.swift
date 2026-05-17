//
//  MessageAction.swift
//  jamly
//
//  Created by REVERSS on 26/02/2026.
//

import Foundation
import UIKit

/// Centralise les chemins d'endpoints liés aux messages individuels.
struct MessageEndpoint {
    static let messages = "/messages"
}

// MARK: - Request Bodies

/// Corps de la requête d'envoi de message texte.
struct SendTextMessageRequest: Codable {
    let conversationId: Int
    let content: String
    let type: String
}

/// Corps de la requête d'envoi de message « share » (lien de morceau ou playlist Apple Music).
struct SendShareMessageRequest: Codable {
    let conversationId: Int
    let content: String
    let type: String
}

/// Corps de la requête d'envoi de message image.
struct SendImageMessageRequest: Codable {
    let conversationId: Int
    /// Image encodée en Base64 préfixée par un data URI (`data:image/jpeg;base64,...`).
    let content: String
    let type: String
}

// MARK: - Message Actions

/// Actions API d'envoi de messages individuels (texte, partage, image).
///
/// Tous les envois passent par le même endpoint `/messages` ; seul le champ `type` du corps
/// change pour indiquer la nature du contenu.
enum MessageAction {
    /// Envoie un message texte dans une conversation.
    ///
    /// - Parameters:
    ///   - conversationId: Identifiant de la conversation cible.
    ///   - content: Texte brut du message (non vide).
    /// - Returns: Le message tel que persisté côté serveur.
    /// - Throws: ``APIError`` en cas d'échec.
    static func sendTextMessage(
        conversationId: Int,
        content: String
    ) async throws -> APIResponse<Message> {
        let body = SendTextMessageRequest(
            conversationId: conversationId,
            content: content,
            type: "text"
        )
        return try await APIClient.shared.request(
            MessageEndpoint.messages,
            method: .post,
            body: body,
            responseType: Message.self
        )
    }

    /// Envoie un message de partage (lien de morceau ou de playlist Apple Music).
    ///
    /// - Parameters:
    ///   - conversationId: Identifiant de la conversation cible.
    ///   - content: URL Apple Music à partager.
    /// - Returns: Le message tel que persisté côté serveur.
    /// - Throws: ``APIError`` en cas d'échec.
    static func sendShareMessage(
        conversationId: Int,
        content: String
    ) async throws -> APIResponse<Message> {
        let body = SendShareMessageRequest(
            conversationId: conversationId,
            content: content,
            type: "share"
        )
        return try await APIClient.shared.request(
            MessageEndpoint.messages,
            method: .post,
            body: body,
            responseType: Message.self
        )
    }
    
    /// Envoie un message image dans une conversation.
    ///
    /// L'image est encodée en JPEG (qualité 0.8) puis transmise en Base64 préfixée par
    /// un data URI, format attendu par le backend.
    ///
    /// - Parameters:
    ///   - conversationId: Identifiant de la conversation cible.
    ///   - image: Image à envoyer.
    /// - Returns: Le message tel que persisté côté serveur.
    /// - Throws: Une erreur générique si l'encodage JPEG échoue, ou ``APIError``
    ///   si l'appel réseau échoue.
    static func sendImageMessage(
        conversationId: Int,
        image: UIImage
    ) async throws -> APIResponse<Message> {
        // Convertir l'image en Base64 avec data URI prefix (comme dans CreatePost)
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(
                domain: "MessageAction",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG"]
            )
        }
        
        let base64String = imageData.base64EncodedString()
        let dataURI = "data:image/jpeg;base64,\(base64String)"
        
        let body = SendImageMessageRequest(
            conversationId: conversationId,
            content: dataURI,
            type: "image"
        )
        
        let response = try await APIClient.shared.request(
            MessageEndpoint.messages,
            method: .post,
            body: body,
            responseType: Message.self
        )
        
        print("✅ Image message sent to conversation \(conversationId)")
        return response
    }
}
