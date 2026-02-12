//
//  ConversationActionswift
//  jamly
//
//  Created by Jonathan Dumesnil on 12/02/2026.
//

enum ConversationAction {
    static func getConversations(page: Int = 1) async throws -> APIResponse<[Conversation]> {
        let response = try await APIClient.shared.request(
            "/conversations",
            method: .get,
            query: ["page": String(page)],
            responseType: [Conversation].self
        )
       
        return response
    }
}
