//
//  CommentAction.swift
//  jamly
//
//  Created by Jonathan Dumesnil on 29/12/2025.
//

/// Corps de la requête de création d'un commentaire.
struct CreateCommentRequest: Encodable {
    let content: String
}

/// Corps de la requête de like d'un commentaire (endpoint générique `/likes`).
struct LikeCommentRequest: Encodable {
    let entityClass: String = "App\\Entity\\Comment"
    let entityId: Int
}

/// Corps de la requête d'unlike d'un commentaire.
struct UnLikeCommentRequest: Encodable {
    let entityClass: String = "App\\Entity\\Comment"
    let entityId: Int
}

/// Actions API liées aux commentaires des posts (création, lecture, likes).
enum CommentAction {
    /// Crée un commentaire sur un post donné.
    ///
    /// - Parameters:
    ///   - postId: Identifiant du post commenté.
    ///   - content: Contenu textuel du commentaire.
    /// - Returns: Le commentaire nouvellement créé, version réduite.
    /// - Throws: ``APIError`` en cas d'échec.
    static func CreateComment(postId: Int, content: String) async throws -> APIResponse<SendCommentResponse> {
        let response = try await APIClient.shared.request(
            "/posts/\(postId)/comments",
            method: .post,
            body: CreateCommentRequest(content: content),
            responseType: SendCommentResponse.self
        )
        
        return response
    }
    
    /// Récupère la liste paginée des commentaires d'un post.
    ///
    /// - Parameters:
    ///   - postId: Identifiant du post.
    ///   - page: Numéro de page (par défaut `1`).
    /// - Throws: ``APIError`` en cas d'échec.
    static func getComments(postId: Int, page: Int = 1) async throws -> APIResponse<[CommentResponse]> {
        let response = try await APIClient.shared.request(
            "/posts/\(postId)/comments",
            method: .get,
            query: ["page": String(page)],
            responseType: [CommentResponse].self
        )

        return response
    }

    /// Récupère un commentaire isolé par son identifiant.
    ///
    /// Utilisé typiquement quand un push notification ouvre un commentaire précis hors de
    /// la liste paginée.
    ///
    /// - Parameter id: Identifiant du commentaire.
    /// - Throws: ``APIError`` ; un `404` indique un commentaire inexistant.
    static func getComment(id: Int) async throws -> APIResponse<CommentResponse> {
        let response = try await APIClient.shared.request(
            "/comments/\(id)",
            method: .get,
            responseType: CommentResponse.self
        )

        return response
    }
    
    /// Like un commentaire pour le compte de l'utilisateur courant.
    ///
    /// - Parameter commentId: Identifiant du commentaire à liker.
    /// - Throws: ``APIError`` ; le serveur tolère les doubles likes (idempotent).
    static func like(commentId: Int) async throws -> APIResponse<EmptyResponse> {
        let response = try await APIClient.shared.request(
            "/likes",
            method: .post,
            body : LikeCommentRequest(entityId: commentId),
            responseType: EmptyResponse.self
        )
        
        return response
    }
    
    /// Supprime un commentaire dont l'utilisateur connecté est l'auteur.
    ///
    /// Le serveur renvoie 403 si l'utilisateur tente de supprimer un commentaire qui n'est
    /// pas le sien.
    ///
    /// - Parameter commentId: Identifiant du commentaire à supprimer.
    /// - Throws: ``APIError`` en cas d'échec.
    static func delete(commentId: Int) async throws -> APIResponse<EmptyResponse> {
        let response = try await APIClient.shared.request(
            "/comments/\(commentId)",
            method: .delete,
            responseType: EmptyResponse.self
        )

        return response
    }

    /// Retire le like précédemment posé sur un commentaire.
    ///
    /// - Parameter commentId: Identifiant du commentaire à unliker.
    /// - Throws: ``APIError`` en cas d'échec.
    static func unlike(commentId: Int) async throws -> APIResponse<EmptyResponse> {
        let response = try await APIClient.shared.request(
            "/likes/delete",
            method: .post,
            body: UnLikeCommentRequest(entityId: commentId),
            responseType: EmptyResponse.self
        )
        
        return response
    }
}
