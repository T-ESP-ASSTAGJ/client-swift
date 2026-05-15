//
//  Comment.swift
//  jamly
//
//  Created by Jonathan Dumesnil on 29/12/2025.
//

/// Commentaire complet tel qu'il est affiché sous un post.
///
/// Contient les compteurs sociaux (`likesCount`, `isLiked`) afin que la vue puisse
/// gérer le toggle de like sans repasser par un endpoint dédié.
struct CommentResponse: Codable, Identifiable {
    let id: Int
    let user: CommonUser
    let content: String
    let likesCount: Int
    /// Indique si l'utilisateur connecté a liké ce commentaire.
    let isLiked: Bool
    let createdAt: String?
}

/// Réponse renvoyée par l'API après la création d'un commentaire.
///
/// Version réduite de ``CommentResponse`` car les compteurs sont nécessairement à zéro
/// au moment de la création.
struct SendCommentResponse: Codable {
    let id: Int
    let user: CommonUser
    let content: String
}
