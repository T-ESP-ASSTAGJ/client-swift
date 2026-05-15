//
//  FollowerAction.swift
//  jamly
//
//  Created by Jonathan Dumesnil on 29/12/2025.
//

/// Actions API liées aux followings (utilisateurs suivis par un utilisateur donné).
enum FollowingAction {
    /// Récupère la liste des utilisateurs suivis par un utilisateur.
    ///
    /// - Parameters:
    ///   - userId: Identifiant de l'utilisateur observé.
    ///   - page: Numéro de page (par défaut `1`).
    /// - Throws: ``APIError`` en cas d'échec.
    // TODO pagination
    static func getFollowingUsers(userId: Int, page: Int = 1) async throws -> APIResponse<[FollowingUser]> {
        let response = try await APIClient.shared.request(
            "/users/\(userId)/following",
            method: .get,
            query: ["page": String(page)],
            responseType: [FollowingUser].self
        )
        
        return response
    }
}
