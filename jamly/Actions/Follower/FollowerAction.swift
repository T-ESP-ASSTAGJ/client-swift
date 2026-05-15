//
//  FollowerAction.swift
//  jamly
//
//  Created by Jonathan Dumesnil on 29/12/2025.
//


/// Actions API liées aux followers (utilisateurs qui suivent un utilisateur donné).
enum FollowerAction {
    /// Récupère la liste des followers d'un utilisateur.
    ///
    /// - Parameters:
    ///   - userId: Identifiant de l'utilisateur dont on veut les followers.
    /// - Throws: ``APIError`` en cas d'échec.
    ///
    static func getFollowerUsers(userId: Int, page: Int = 1) async throws -> APIResponse<[FollowerUser]> {
        let response = try await APIClient.shared.request(
            "/users/\(userId)/followers",
            method: .get,
            query: ["page": String(1)],
            responseType: [FollowerUser].self
        )
        
        return response
    }
}
