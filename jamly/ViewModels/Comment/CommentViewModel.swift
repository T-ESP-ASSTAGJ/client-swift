//
//  CommentViewModel.swift
//  jamly
//
//  Created by Jonathan Dumesnil on 31/12/2025.
//

import Foundation
import Combine

@MainActor
final class CommentViewModel: ObservableObject {
    enum VerifyState {
        case loading
        case success
        case error
    }
    
    @Published var comments: [CommentResponse] = []
    @Published var state: VerifyState = .loading
    @Published var isLoading: Bool = false
    
    private var currentPage: Int = 1
    private var hasMorePages: Bool = true
    private var currentPostId: Int?
    private var highlightedCommentId: Int?
    
    @Published var isLoadingMore: Bool = false
    @Published var errorMessage: String?
    
    func getComments(post: Post, highlightedCommentId: Int? = nil) async {
        Task {
            isLoading = true
            errorMessage = nil
            currentPage = 1
            state = .loading
            hasMorePages = true
            currentPostId = post.id
            self.highlightedCommentId = highlightedCommentId

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
            
            return commentResponse
        } catch {
            print("❌ Failed to send comment: \(error)")
            errorMessage = "Failed to send comment"
            throw error
        }
    }
}


