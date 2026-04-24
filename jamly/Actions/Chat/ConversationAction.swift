//
//  ConversationActionswift
//  jamly
//
//  Created by Jonathan Dumesnil on 12/02/2026.
//

struct ConversationEndpoint {
    static let conversations = "/conversations"
    static let createConversation = "/conversations"
    
    static func conversation(_ id: Int) -> String { "/conversations/\(id)" }
    static func deleteConversation(_ id: Int) -> String { "/conversations/\(id)" }
    static func markAsRead(_ id: Int) -> String { "/conversations/\(id)/read"}
}

struct ConversationRequestResponse: Codable {
    let isGroup: Bool
    let groupName: String?
    let participants: [Int]
}

enum ConversationAction {
    static func getConversations(page: Int = 1) async throws -> APIResponse<[Conversation]> {
        let response = try await APIClient.shared.request(
            ConversationEndpoint.conversations,
            method: .get,
            query: ["page": String(page)],
            responseType: [Conversation].self
        )
               
        return response
    }
    
    static func getConversationDetail(conversationId: Int) async throws -> APIResponse<ConversationDetail> {
        let response = try await APIClient.shared.request(
            ConversationEndpoint.conversation(conversationId),
            method: .get,
            responseType: ConversationDetail.self
        )

        
        return response
    }
    
    static func deleteConversation(id: Int) async throws -> APIResponse<EmptyResponse> {
        let response = try await APIClient.shared.request(
            ConversationEndpoint.deleteConversation(id),
            method: .delete,
            responseType: EmptyResponse.self
        )
        
        print("✅ Conversation \(id) deleted from server")
        return response
    }
    
    static func markAsRead(id: Int) async throws -> APIResponse<EmptyResponse> {
        
        let response = try await APIClient.shared.request(
            ConversationEndpoint.markAsRead(id),
            method: .post,
            responseType: EmptyResponse.self
        )
        
        return response
    }
    
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
