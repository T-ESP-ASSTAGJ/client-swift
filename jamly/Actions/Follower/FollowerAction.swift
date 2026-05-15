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
    ///   - page: Numéro de page (par défaut `1`).
    /// - Throws: ``APIError`` en cas d'échec.
    ///
    /// - Note: La pagination n'est pas encore propagée côté serveur — la valeur du paramètre
    ///   `page` est ignorée et `1` est forcé. Voir le TODO ci-dessous.
    // TODO pagination
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
