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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        // username/counts peuvent être null côté API pour un compte fraîchement créé,
        // d'où le fallback plutôt qu'un decode strict.
        self.username = (try? container.decodeIfPresent(String.self, forKey: .username)) ?? ""
        self.email = try container.decode(String.self, forKey: .email)
        self.profilePicture = try? container.decodeIfPresent(String.self, forKey: .profilePicture)
        self.phoneNumber = try? container.decodeIfPresent(String.self, forKey: .phoneNumber)
        self.bio = try? container.decodeIfPresent(String.self, forKey: .bio)
        self.followingCount = (try? container.decodeIfPresent(Int.self, forKey: .followingCount)) ?? 0
        self.followersCount = (try? container.decodeIfPresent(Int.self, forKey: .followersCount)) ?? 0
    }

    /// URL effective à utiliser pour afficher la photo de profil, avec fallback configurable
    /// (voir ``Config/defaultProfilePictureURL``) quand l'utilisateur n'a pas défini de photo.
    var displayProfilePictureURL: String {
        Self.displayProfilePictureURL(from: profilePicture)
    }

    static func displayProfilePictureURL(
        from profilePicture: String?,
        fallback: String = Config.defaultProfilePictureURL
    ) -> String {
        if let picture = profilePicture, !picture.isEmpty {
            return picture
        }
        return fallback
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
