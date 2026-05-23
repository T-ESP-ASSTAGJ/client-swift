//
//  Post.swift
//  jamly
//
//  Created by REVERSS on 08/12/2025.
//

/// Corps de la requête envoyée à l'API pour créer un nouveau post.
///
/// Le morceau est dénormalisé dans `TrackInput` afin que le backend puisse
/// créer la track côté serveur si elle n'existe pas encore.
struct CreatePostRequest: Codable {
    let caption: String
    let track: TrackInput
    let frontImage: String
    let backImage: String
    let location: String

    /// Détails du morceau partagé, tels que récupérés depuis Apple Music.
    struct TrackInput: Codable {
        let songId: String
        let title: String
        let artistName: String
        let releaseYear: Int
        let coverImage: String
    }
}

/// Publication de la feed Jamly : photo avant/arrière, morceau associé et compteurs sociaux.
///
/// L'égalité et le hachage sont basés uniquement sur ``id`` afin de garantir un comportement
/// stable dans les listes SwiftUI (`ForEach`, animations), même si les compteurs varient.
struct Post: Codable, Identifiable, Hashable {
    let id: Int
    let user: User
    let caption: String
    let track: Track
    let frontImage: String
    let backImage: String
    let location: String
    let commentsCount: Int
    let likesCount: Int
    /// Indique si l'utilisateur connecté a liké ce post.
    let isLiked: Bool
    let viewsCount: Int
    let createdAt: String

    /// Auteur du post, version réduite avec uniquement les champs nécessaires à l'affichage.
    ///
    /// `profilePicture` est optionnel car l'API peut renvoyer `null` pour les utilisateurs
    /// n'ayant pas défini de photo de profil.
    struct User: Codable {
        let id: Int
        let username: String
        let profilePicture: String?
        let createdAt: String
    }

    /// Morceau associé au post, tel qu'enregistré côté backend.
    struct Track: Codable {
        let id: Int
        let songId: String
        let title: String
        let artistName: String
        let coverImage: String
        let releaseYear: Int
        let createdAt: String
    }

    // Hashable & Equatable conformance based on stable identifier
    static func == (lhs: Post, rhs: Post) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
