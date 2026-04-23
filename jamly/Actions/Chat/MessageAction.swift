//
//  MessageAction.swift
//  jamly
//
//  Created by REVERSS on 26/02/2026.
//

import Foundation

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
}
