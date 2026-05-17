//
//  SearchAction.swift
//  jamly
//
//  Created by Alexandre Vandenbulcke on 30/12/2025.
//

import Foundation

/// Actions API liées à la recherche d'utilisateurs.
enum SearchAction {
    /// Recherche des utilisateurs par nom d'utilisateur avec pagination.
    ///
    /// - Parameters:
    ///   - username: Texte de recherche (sous-chaîne ou nom complet).
    ///   - page: Numéro de page (par défaut `1`).
    /// - Returns: Les utilisateurs correspondant à la requête.
    /// - Throws: ``APIError`` en cas d'échec.
    static func searchUsers(username: String, page: Int = 1) async throws -> APIResponse<[SearchUser]> {
        let response = try await APIClient.shared.request(
            "/users",
            method: .get,
            query: [
                "username": username,
                "page": String(page)
            ],
            responseType: [SearchUser].self
        )
        
        print("🔍 Search results for '\(username)' (page \(page)): \(response.value.count) users found")
        
        return response
    }
}
