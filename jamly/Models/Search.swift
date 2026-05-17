//
//  SearchModels.swift
//  jamly
//
//  Created by Alexandre Vandenbulcke on 30/12/2025.
//

import Foundation

/// Utilisateur retourné par l'endpoint de recherche.
///
/// `email` est optionnel car non renvoyé pour les utilisateurs autres que le profil connecté.
struct SearchUser: Codable, Identifiable {
    let id: Int
    let username: String
    let email: String?
    let profilePicture: String?

    enum CodingKeys: String, CodingKey {
        case id, username, email, profilePicture
    }
}

/// Enveloppe générique pour les réponses paginées de l'API.
///
/// Permet de réutiliser le même schéma de pagination pour différents types d'entités
/// (utilisateurs, posts, etc.). Le champ `hasMore` est l'indicateur principal pour
/// déclencher le chargement de la page suivante en infinite scroll.
struct PaginatedResponse<T: Codable>: Codable {
    let data: [T]
    let page: Int
    let totalPages: Int
    let totalItems: Int
    let hasMore: Bool

    enum CodingKeys: String, CodingKey {
        case data, page, totalPages, totalItems, hasMore
    }
}

/// Réponse de l'endpoint de recherche d'utilisateurs.
///
/// Décodage tolérant : l'API peut renvoyer soit un tableau JSON brut, soit un objet
/// `{ "users": [...] }`. Le décodeur essaie les deux formes successivement.
struct SearchUsersResponse: Codable {
    let users: [SearchUser]

    /// Décodage tolérant : essaie un tableau brut puis bascule sur la forme objet.
    ///
    /// - Throws: Une erreur de décodage si aucun des deux formats n'est applicable.
    init(from decoder: Decoder) throws {
        // Try to decode as array directly
        if let container = try? decoder.singleValueContainer(),
           let users = try? container.decode([SearchUser].self) {
            self.users = users
        } else {
            // Or try to decode with "users" key
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.users = try container.decode([SearchUser].self, forKey: .users)
        }
    }

    enum CodingKeys: String, CodingKey {
        case users
    }
}
