//
//  MessageAction.swift
//  jamly
//
//  Created by REVERSS on 26/02/2026.
//

import Foundation
import UIKit

struct MessageEndpoint {
    static let messages = "/messages"
}

// MARK: - Request Bodies

struct SendTextMessageRequest: Codable {
    let conversationId: Int
    let content: String
    let type: String
}

struct SendShareMessageRequest: Codable {
    let conversationId: Int
    let content: String
    let type: String
}

struct SendImageMessageRequest: Codable {
    let conversationId: Int
    let content: String  // Image en Base64 avec data URI prefix
    let type: String
}

struct SendImageMessageRequest: Codable {
    let conversationId: Int
    let content: String  // Image en Base64 avec data URI prefix
    let type: String
}

// MARK: - Message Actions

enum MessageAction {
    /// Envoie un message texte dans une conversation
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

    /// Envoie un message de partage (track ou playlist) dans une conversation
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
    
    /// Envoie un message image dans une conversation
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
    
    /// Envoie un message image dans une conversation
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
