//
//  ProfileViewModel.swift
//  jamly
//
//  Created by REVERSS on 30/12/2025.
//

import Foundation
import Combine

@MainActor
final class PostViewModel: ObservableObject {
    enum VerifyState {
        case loading
        case success
        case error
    }
    
    @Published var state: VerifyState = .loading
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Actions
    
    func likePost(post: Post) {
        Task {
            errorMessage = nil
            
            do {
                let response = try await PostActions.likePost(post: post)
                
                switch response.statusCode {
                case 204:
                    state = .success
                    
                case 422:
                    state = .error
                    errorMessage = "An error occurred. Please try again."
                    
                default:
                    state = .error
                    errorMessage = "An error occurred."
                }
            } catch {
                state = .error
                errorMessage = "An error occurred."
            }
        }
    }
    
    func unlikePost(post: Post) {
        Task {
            errorMessage = nil
            
            do {
                let response = try await PostActions.unlikePost(post: post)
                
                switch response.statusCode {
                case 204:
                    state = .success
                    
                case 422:
                    state = .error
                    errorMessage = "An error occurred. Please try again."
                    
                default:
                    state = .error
                    errorMessage = "An error occurred."
                }
            } catch {
                state = .error
                errorMessage = "An error occurred."
            }
        }
    }
    
    func viewPost(post:Post){
        Task{
            errorMessage = nil
            
            do {
                let response = try await PostActions.viewPost(post: post)
                
                switch response.statusCode {
                case 200:
                    state = .success
                    
                case 422:
                    state = .error
                    errorMessage = "An error occurred. Please try again."
                    
                default:
                    state = .error
                    errorMessage = "An error occurred."
                }
            } catch {
                state = .error
                errorMessage = "An error occurred."
            }
        }
    }
}




