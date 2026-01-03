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
    @Published var errorMessage: String?
    
    func getComments(post: Post) async {
        Task {
            isLoading = true
            errorMessage = nil
            state = .loading

            do {
                let response = try await CommentAction.getComments(postId: post.id)

                switch response.statusCode {
                case 200:
                    state = .success
                    comments = response.value

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


