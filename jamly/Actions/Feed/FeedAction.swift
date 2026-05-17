//
//  PostAction.swift
//  jamly
//
//  Created by REVERSS on 08/12/2025.
//

/// Actions API liées aux feeds de posts (Discovery public et Friends privé).
enum FeedAction{
    /// Récupère la page demandée du feed Discovery (posts publics).
    ///
    /// - Parameter page: Numéro de page (par défaut `1`).
    /// - Throws: ``APIError`` en cas d'échec.
    static func getPublicFeed(page: Int = 1) async throws -> APIResponse<[Post]> {
        let response = try await APIClient.shared.request(
            "/feed/public",
            method: .get,
            query: ["page": String(page)],
            responseType: [Post].self
        )
        
        return response
    }
    
    /// Récupère la page demandée du feed Friends (posts des utilisateurs suivis).
    ///
    /// - Parameter page: Numéro de page (par défaut `1`).
    /// - Throws: ``APIError`` en cas d'échec.
    static func getPrivateFeed(page: Int = 1) async throws -> APIResponse<[Post]> {
        let response = try await APIClient.shared.request(
            "/feed/private",
            method: .get,
            query: ["page": String(page)],
            responseType: [Post].self
        )
        
        return response
    }
}
