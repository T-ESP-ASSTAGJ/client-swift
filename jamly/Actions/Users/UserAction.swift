//
//  User.swift
//  jamly
//
//  Created by REVERSS on 06/12/2025.
//


// Actions/UserActions.swift
import Foundation

// MARK: - Endpoints

/// Chemins relatifs des endpoints liés aux utilisateurs.
///
/// Regrouper ces constantes en un seul point permet de modifier l'arborescence de l'API
/// sans avoir à parcourir tous les appels.
struct UserEndpoints {
    // Base paths
    static let me = "/users/me"
    static let users = "/users"
    static let posts = "/posts"

    // Helpers to build parameterized paths
    static func user(_ id: Int) -> String { "/users/\(id)" }
    static func follow(_ id: Int) -> String { "/users/\(id)/follow" }
    static func unfollow(_ id: Int) -> String { "/users/\(id)/unfollow" }
    static func likes(_ id: Int) -> String { "/users/\(id)/likes" }
}


/// Actions API liées aux utilisateurs (profil, follow, posts associés).
enum UserActions {
    /// Récupère le profil complet de l'utilisateur actuellement connecté.
    ///
    /// - Throws: ``APIError`` ; un `401` déclenche la déconnexion automatique via ``APIClient``.
    static func fetchMe() async throws -> APIResponse<User> {
        let response = try await APIClient.shared.request(
            UserEndpoints.me,
            method: .get,
            responseType: User.self
        )
        
        print("😁 /ME \(response.value)")
        
        return response
    }
    
    /// Récupère le profil public d'un utilisateur par son identifiant.
    ///
    /// - Parameter userId: Identifiant de l'utilisateur cible.
    /// - Throws: ``APIError`` ; un `404` indique un utilisateur inexistant.
    static func getUserById(userId: Int) async throws -> APIResponse<User> {
        let response = try await APIClient.shared.request(
            UserEndpoints.user(userId),
            method: .get,
            responseType: User.self
        )
        
        print("👤 Fetched user \(userId): \(response.value.username)")
        
        return response
    }
    
    /// Suit un utilisateur.
    ///
    /// - Parameter userId: Identifiant de l'utilisateur à suivre.
    /// - Throws: ``APIError`` ; l'opération est idempotente côté serveur.
    static func followUser(userId: Int) async throws -> APIResponse<EmptyResponse> {
        let response = try await APIClient.shared.request(
            UserEndpoints.follow(userId),
            method: .post,
            responseType: EmptyResponse.self
        )
        
        print("✅ Followed user \(userId)")
        
        return response
    }
    
    /// Cesse de suivre un utilisateur.
    ///
    /// - Parameter userId: Identifiant de l'utilisateur à ne plus suivre.
    /// - Throws: ``APIError`` en cas d'échec.
    static func unfollowUser(userId: Int) async throws -> APIResponse<EmptyResponse> {
        let response = try await APIClient.shared.request(
            UserEndpoints.unfollow(userId),
            method: .delete,
            responseType: EmptyResponse.self
        )
        
        print("❌ Unfollowed user \(userId)")
        
        return response
    }
    
    /// Récupère les posts likés par un utilisateur donné.
    ///
    /// - Parameters:
    ///   - userId: Identifiant de l'utilisateur observé.
    ///   - page: Numéro de page (par défaut `1`).
    /// - Throws: ``APIError`` en cas d'échec.
    static func getLikedPostsByUser(userId: Int, page: Int = 1) async throws -> APIResponse<[Post]> {
        let response = try await APIClient.shared.request(
            UserEndpoints.likes(userId),
            method: .get,
            query: ["page": String(page)],
            responseType: [Post].self
        )
        
        return response
    }
    
    /// Récupère les posts publiés par un utilisateur donné.
    ///
    /// - Parameters:
    ///   - userId: Identifiant de l'utilisateur observé.
    ///   - page: Numéro de page (par défaut `1`).
    /// - Throws: ``APIError`` en cas d'échec.
    static func getPostsByUser(userId: Int, page: Int = 1) async throws -> APIResponse<[Post]> {
        let response = try await APIClient.shared.request(
            UserEndpoints.posts,
            method: .get,
            query: ["user": "\(userId)", "page": String(page)],
            responseType: [Post].self
        )
        
        print("📝 Found \(response.value.count) posts of user \(userId)")
        
        return response
    }
    
    /// Met à jour partiellement le profil de l'utilisateur connecté (PATCH).
    ///
    /// Seuls les champs non-`nil` sont envoyés au serveur, ce qui permet de modifier un
    /// seul attribut à la fois (champ vide vs. champ non modifié).
    ///
    /// - Parameters:
    ///   - username: Nouveau nom d'utilisateur, ou `nil` pour le laisser inchangé.
    ///   - phoneNumber: Nouveau numéro de téléphone.
    ///   - bio: Nouvelle biographie.
    ///   - profilePicture: Nouvelle photo de profil (URL ou data URI selon le serveur).
    /// - Returns: Le profil utilisateur mis à jour tel que renvoyé par le serveur.
    /// - Throws: ``APIError`` ; un `409` indique un conflit (nom d'utilisateur déjà pris).
    static func updateProfile(username: String?, phoneNumber: String?, bio: String?, profilePicture: String?) async throws -> APIResponse<User> {
        /// Corps de la requête PATCH `/users/me`. Les valeurs `nil` sont omises par
        /// le `JSONEncoder` lors de la sérialisation.
        struct UpdateProfileRequest: Codable {
            let username: String?
            let phoneNumber: String?
            let bio: String?
            let profilePicture: String?
        }
        
        let body = UpdateProfileRequest(
            username: username,
            phoneNumber: phoneNumber,
            bio: bio,
            profilePicture: profilePicture
        )
        
        let response = try await APIClient.shared.request(
            UserEndpoints.me,
            method: .patch,
            body: body,
            responseType: User.self
        )
        
        return response
    }
    
    /// Supprime définitivement un compte utilisateur.
    ///
    /// Côté app, l'appel doit toujours porter sur l'utilisateur connecté ; le serveur
    /// refusera toute suppression d'un autre compte.
    ///
    /// - Parameter userId: Identifiant du compte à supprimer.
    /// - Throws: ``APIError`` en cas d'échec.
    static func deleteAccount(userId: Int) async throws -> APIResponse<EmptyResponse> {
        let response = try await APIClient.shared.request(
            UserEndpoints.user(userId),
            method: .delete,
            responseType: EmptyResponse.self
        )
        
        return response
    }
}
