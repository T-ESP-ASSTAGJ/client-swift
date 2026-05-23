//
//  CommentViewModel.swift
//  jamly
//
//  Created by Jonathan Dumesnil on 31/12/2025.
//

import Foundation
import Combine

/// ViewModel de la vue des commentaires d'un post.
///
/// Gère le chargement paginé, l'envoi de nouveaux commentaires et l'épinglage en tête
/// d'un commentaire ciblé par push notification (deep link).
@MainActor
final class CommentViewModel: ObservableObject {
    /// État de la requête de chargement des commentaires.
    enum VerifyState {
        case loading
        case success
        case error
    }

    @Published var comments: [CommentResponse] = []
    @Published var state: VerifyState = .loading
    @Published var isLoading: Bool = false
    /// Total de commentaires sur le post (source de vérité pour les compteurs affichés).
    /// Initialisé depuis `post.commentsCount` puis maintenu localement à chaque envoi/suppression
    /// pour éviter de re-fetcher le post entier juste pour mettre à jour un titre.
    @Published var commentsCount: Int = 0

    private var currentPage: Int = 1
    private var hasMorePages: Bool = true
    private var currentPostId: Int?
    /// Identifiant d'un commentaire ouvert via deep link, épinglé en tête de liste.
    private var highlightedCommentId: Int?

    @Published var isLoadingMore: Bool = false
    @Published var errorMessage: String?

    /// Charge les commentaires d'un post, avec épinglage optionnel d'un commentaire spécifique.
    ///
    /// Le commentaire épinglé est récupéré séparément via ``CommentAction/getComment(id:)``
    /// pour garantir qu'il s'affiche en tête, même s'il appartient à une page ultérieure.
    /// Les autres commentaires sont chargés via la pagination standard.
    ///
    /// - Parameters:
    ///   - post: Post dont on charge les commentaires.
    ///   - highlightedCommentId: Commentaire à épingler (issu d'un deep link), ou `nil`.
    func getComments(post: Post, highlightedCommentId: Int? = nil) async {
        Task {
            isLoading = true
            errorMessage = nil
            currentPage = 1
            state = .loading
            hasMorePages = true
            currentPostId = post.id
            self.highlightedCommentId = highlightedCommentId
            commentsCount = post.commentsCount

            do {
                // Commentaire mis en avant (récupéré à part pour garantir qu'il s'affiche)
                var highlighted: CommentResponse?
                if let highlightedCommentId {
                    do {
                        let highlightedResponse = try await CommentAction.getComment(id: highlightedCommentId)
                        if highlightedResponse.statusCode == 200 {
                            highlighted = highlightedResponse.value
                            print("⭐ Commentaire mis en avant chargé: \(highlightedCommentId)")
                        }
                    } catch {
                        print("⚠️ Impossible de charger le commentaire \(highlightedCommentId): \(error)")
                    }
                }

                print("📥 Loading comments for post \(post.id), page \(currentPage)")
                let response = try await CommentAction.getComments(postId: post.id)

                switch response.statusCode {
                case 200:
                    state = .success
                    var loaded = response.value
                    if let highlighted {
                        loaded.removeAll { $0.id == highlighted.id }
                        loaded.insert(highlighted, at: 0)
                    }
                    comments = loaded

                    print("✅ Loaded \(response.value.count) comments")
                    hasMorePages = response.value.count >= 20
                    print("📄 Has more pages: \(hasMorePages)")
                default:
                    state = .error
                    errorMessage = "❌ Failed to load comments: \(state)"
                }
            } catch {
                state = .error
                errorMessage = "Failed to load comments: \(state)"
            }

            isLoading = false
        }
    }
    
    
    /// Charge la page suivante de commentaires (infinite scroll).
    ///
    /// Si un commentaire est épinglé, il est filtré des nouvelles pages pour éviter un doublon
    /// avec la tête de liste. En cas d'erreur, ``currentPage`` est décrémenté pour autoriser
    /// une nouvelle tentative.
    func loadMoreComments() async {
        guard !isLoadingMore, !isLoading, hasMorePages, let postId = currentPostId else {
            return
        }
        Task {
            isLoadingMore = true
            errorMessage = nil
            
            do {
                currentPage += 1
                let response = try await CommentAction.getComments(postId: postId, page: currentPage)
                
                switch response.statusCode {
                case 200:
                    var newComments = response.value
                    if let highlightedCommentId {
                        newComments.removeAll { $0.id == highlightedCommentId }
                    }
                    comments.append(contentsOf: newComments)
                    hasMorePages = response.value.count >= 20
                default:
                    errorMessage = "Failed to load comments."
                    currentPage = currentPage - 1
                }
            } catch {
                errorMessage = "Failed to load comments."
            }
            isLoadingMore = false
        }
    }
    
    /// Envoie un nouveau commentaire et l'insère en tête de la liste locale.
    ///
    /// Le serveur ne renvoie pas les compteurs (forcément à zéro à la création) ; ils sont
    /// initialisés à `0` côté client. Le commentaire reste affiché de manière optimiste
    /// même si un fetch ultérieur le repositionne.
    ///
    /// - Parameters:
    ///   - postId: Identifiant du post commenté.
    ///   - content: Contenu textuel du commentaire (non vide).
    /// - Returns: Le commentaire créé tel qu'inséré dans ``comments``.
    /// - Throws: ``APIError`` ou toute erreur renvoyée par ``CommentAction/CreateComment(postId:content:)``.
    /// Supprime un commentaire dont l'utilisateur connecté est l'auteur, et le retire
    /// de la liste locale de façon optimiste.
    ///
    /// - Parameter commentId: Identifiant du commentaire à supprimer.
    /// - Returns: `true` si la suppression a réussi, `false` sinon (le commentaire est
    ///   alors restauré dans la liste).
    @discardableResult
    func deleteComment(commentId: Int) async -> Bool {
        guard let index = comments.firstIndex(where: { $0.id == commentId }) else {
            return false
        }
        let removed = comments.remove(at: index)

        commentsCount = max(0, commentsCount - 1)

        do {
            _ = try await CommentAction.delete(commentId: commentId)
            return true
        } catch {
            print("❌ Failed to delete comment \(commentId): \(error)")
            comments.insert(removed, at: index)
            commentsCount += 1
            errorMessage = "Failed to delete comment"
            return false
        }
    }

    func sendComment(postId: Int, content: String) async throws -> CommentResponse {
        errorMessage = nil
        
        do {
            print("📤 Sending comment: '\(content)'")
            let response = try await CommentAction.CreateComment(postId: postId, content: content)
            
            print("✅ Comment sent successfully: \(response)")
            
            // Convertir la réponse en CommentResponse
            let commentResponse = CommentResponse(
                id: response.value.id,
                user: response.value.user,
                content: response.value.content,
                likesCount: 0,
                isLiked: false,
                createdAt: nil
            )
            
            // Ajouter le commentaire à la liste
            comments.insert(commentResponse, at: 0)
            commentsCount += 1

            return commentResponse
        } catch {
            print("❌ Failed to send comment: \(error)")
            errorMessage = "Failed to send comment"
            throw error
        }
    }
}


