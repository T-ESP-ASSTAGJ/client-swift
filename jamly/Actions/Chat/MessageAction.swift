//
//  MessageAction.swift
//  jamly
//
//  Created by REVERSS on 26/02/2026.
//

import Foundation

// MARK: - Request Bodies

struct SendTextMessageRequest: Codable {
    let conversationId: Int
    let content: String
    let type: String
}

struct SendMusicMessageRequest: Codable {
    let trackId: Int
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
        
        let response = try await APIClient.shared.request(
            "/messages",
            method: .post,
            body: body,
            responseType: Message.self
        )
        
        print("✅ Text message sent to conversation \(conversationId)")
        return response
    }
    
    /// Envoie un message musical (track) dans une conversation
    static func sendMusicMessage(
        conversationId: Int,
        trackId: Int
    ) async throws -> APIResponse<Message> {
        let body = SendMusicMessageRequest(
            trackId: trackId,
            type: "music"
        )
        
        let response = try await APIClient.shared.request(
            "/conversations/\(conversationId)/messages",
            method: .post,
            body: body,
            responseType: Message.self
        )
        
        print("✅ Music message sent to conversation \(conversationId)")
        return response
    }
}
