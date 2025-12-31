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
}


