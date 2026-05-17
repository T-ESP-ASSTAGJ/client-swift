//
//  PostAction.swift
//  jamly
//
//  Created by REVERSS on 08/12/2025.
//

/// Réponse de l'endpoint de création de post ; ne contient que l'identifiant.
struct CreatePostRequestResponse: Decodable {
    let id: Int
}

/// Réponse de l'endpoint de création de signalement ; ne contient que l'identifiant.
struct CreateReportResponse: Decodable {
    let id: Int
}

/// Corps des requêtes de like/unlike sur un post, via l'endpoint générique `/likes`.
struct LikePostBody: Encodable {
    let entityClass: String = "App\\Entity\\Post"
    let entityId: Int
}

/// Chemins relatifs des endpoints liés aux posts.
struct PostEndpoint {
    static let posts = "/posts"
    static func viewPost(_ postId: Int) -> String { "/posts/\(postId)/view" }
}

/// Chemins relatifs des endpoints de likes (entités génériques).
struct LikeEndpoint {
    static let likes = "/likes"
    static let deleteLike = "/likes/delete"
}

/// Chemins relatifs des endpoints liés aux signalements.
struct ReportEndpoint {
    static let report = "/reports"
    static let reportReasons = "/reports-reasons"
}

/// Actions API liées aux posts (création, lecture, likes, vues, signalements).
enum PostActions {
    /// Récupère un post par son identifiant.
    ///
    /// - Parameter id: Identifiant du post.
    /// - Throws: ``APIError`` ; un `404` indique un post supprimé ou inexistant.
    static func fetchPost(id: Int) async throws -> APIResponse<Post> {
        let response = try await APIClient.shared.request(
            "/posts/\(id)",
            method: .get,
            responseType: Post.self
        )
        
        return response
    }
    
    /// Crée un nouveau post.
    ///
    /// - Parameter post: Données complètes du post à publier (caption, track, images, lieu).
    /// - Returns: L'identifiant du post nouvellement créé.
    /// - Throws: ``APIError`` en cas d'échec.
    static func create(post: CreatePostRequest) async throws -> APIResponse<CreatePostRequestResponse> {
        let response = try await APIClient.shared.request(
            PostEndpoint.posts,
            method: .post,
            body: post,
            responseType: CreatePostRequestResponse.self
        )
        
        print(response)
        
        return response
    }
    
    /// Like un post pour le compte de l'utilisateur courant.
    ///
    /// - Parameter post: Post à liker.
    /// - Throws: ``APIError`` ; l'opération est idempotente côté serveur.
    static func likePost(post: Post) async throws -> APIResponse<EmptyResponse> {
        let body = LikePostBody(entityId: post.id)
        
        let response = try await APIClient.shared.request(
            LikeEndpoint.likes,
            method: .post,
            body: body,
            responseType: EmptyResponse.self
        )
        
        print("❤️ Post \(post.id) Liked!")
        
        return response
    }
    
    /// Retire le like précédemment posé sur un post.
    ///
    /// - Parameter post: Post à unliker.
    /// - Throws: ``APIError`` en cas d'échec.
    static func unlikePost(post: Post) async throws -> APIResponse<EmptyResponse> {
        let body = LikePostBody(entityId: post.id)
        
        let response = try await APIClient.shared.request(
            LikeEndpoint.deleteLike,
            method: .post,
            body: body,
            responseType: EmptyResponse.self
        )
        
        print("❤️ Post \(post.id) Unliked!")
        
        return response
    }
    
    /// Notifie le serveur qu'un post a été vu par l'utilisateur courant.
    ///
    /// Utilise un `PATCH` car l'opération met à jour le compteur de vues côté backend.
    ///
    /// - Parameter post: Post visualisé.
    /// - Throws: ``APIError`` en cas d'échec.
    static func viewPost(post: Post) async throws -> APIResponse<EmptyResponse> {
        let postId = post.id

        let response = try await APIClient.shared.request(
            PostEndpoint.viewPost(postId),
            method: .patch,
            responseType: EmptyResponse.self
        )

        return response
    }

    /// Récupère la liste des motifs de signalement proposés par le serveur.
    ///
    /// Les motifs sont localisés côté backend, donc l'app les affiche tels quels.
    ///
    /// - Throws: ``APIError`` en cas d'échec.
    static func fetchReportReasons() async throws -> APIResponse<[ReportReason]> {
        let response = try await APIClient.shared.request(
            ReportEndpoint.reportReasons,
            method: .get,
            responseType: [ReportReason].self
        )
        return response
    }

    /// Signale un post auprès du serveur.
    ///
    /// - Parameters:
    ///   - postId: Identifiant du post signalé.
    ///   - reason: Clé du motif (issue de ``ReportReason/key``).
    ///   - message: Commentaire libre fourni par l'utilisateur.
    /// - Throws: ``APIError`` en cas d'échec.
    static func reportPost(postId: Int, reason: String, message: String) async throws -> APIResponse<EmptyResponse> {
        let body = ReportBody(entityId: postId, reason: reason, message: message)
        let response = try await APIClient.shared.request(
            ReportEndpoint.report,
            method: .post,
            body: body,
            responseType: EmptyResponse.self
        )
        return response
    }
}
