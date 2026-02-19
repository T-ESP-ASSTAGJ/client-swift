//
//  ConversationActionswift
//  jamly
//
//  Created by Jonathan Dumesnil on 12/02/2026.
//

struct ConversationRequestResponse: Codable {
    let isGroup: Bool
    let groupName: String
    let participants: [Int]
}

enum ConversationAction {
    static func getConversations(page: Int = 1) async throws -> APIResponse<[Conversation]> {
        let response = try await APIClient.shared.request(
            "/conversations",
            method: .get,
            query: ["page": String(page)],
            responseType: [Conversation].self
        )
        
        print(response)
       
        return response
    }
    
    static func deleteConversation(id: Int) async throws -> APIResponse<EmptyResponse> {
        let response = try await APIClient.shared.request(
            "/conversations/\(id)",
            method: .delete,
            responseType: EmptyResponse.self
        )
        
        print("✅ Conversation \(id) deleted from server")
        return response
    }
    
    static func markAsRead(id: Int, isRead: Bool) async throws -> APIResponse<Conversation> {
        let body = ["isRead": isRead]
        
        let response = try await APIClient.shared.request(
            "/conversations/\(id)/read",
            method: .patch,
            body: body,
            responseType: Conversation.self
        )
        
        print("✅ Conversation \(id) marked as \(isRead ? "read" : "unread")")
        return response
    }
    
    static func createConversation(
        isGroup: Bool,
        groupName: String,
        participants: [Int]
    ) async throws -> APIResponse<Conversation> {
        let response = try await APIClient.shared.request(
            "/conversations",
            method: .post,
            body: ConversationRequestResponse(isGroup: isGroup, groupName: groupName, participants: participants),
            responseType: Conversation.self
        )
        
        return response
    }
}
