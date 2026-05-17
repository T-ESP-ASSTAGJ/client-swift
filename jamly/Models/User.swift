//
//  User.swift
//  jamly
//
//  Created by REVERSS on 07/12/2025.
//

/// Profil utilisateur complet retourné par l'API.
///
/// Représente l'utilisateur connecté ou un autre utilisateur consulté via son profil.
/// Pour des affichages plus légers (liste de messages, de followers…), préférer ``CommonUser``,
/// ``FollowerUser`` ou ``FollowingUser``.
struct User: Codable {
    let id: Int
    let username: String
    let email: String
    let profilePicture: String?
    let phoneNumber: String?
    let bio: String?
    let followingCount: Int
    let followersCount: Int

    enum CodingKeys: String, CodingKey {
        case id, username, email, profilePicture, phoneNumber, bio, followingCount, followersCount
    }
}


/// Utilisateur tel qu'il apparaît dans la liste des followers.
///
/// Version allégée de ``User`` sans email, bio ni compteurs : seul le nécessaire à l'affichage
/// dans une cellule est sérialisé.
struct FollowerUser: Codable, Identifiable, Equatable {
    let id: Int
    let username: String
    let profilePicture: String

}

/// Utilisateur tel qu'il apparaît dans la liste des followings (utilisateurs suivis).
struct FollowingUser: Codable, Identifiable {
    let id: Int
    let username: String
    let profilePicture: String
}

/// Représentation minimale d'un utilisateur, utilisée comme auteur dans les messages,
/// commentaires, participants de conversation, etc.
///
/// `profilePicture` est optionnel car certains endpoints renvoient un utilisateur
/// sans avatar configuré.
struct CommonUser: Codable, Hashable {
    let id: Int
    let username: String
    let profilePicture: String?
}
