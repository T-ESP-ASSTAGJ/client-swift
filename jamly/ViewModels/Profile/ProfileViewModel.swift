//
//  ProfileViewModel.swift
//  jamly
//
//  Created by REVERSS on 30/12/2025.
//

import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    enum VerifyState {
        case loading
        case success
        case error
    }
    
    @Published var profileUser: User?
    @Published var likedPosts: [Post] = []
    @Published var posts : [Post] = []
    @Published var state: VerifyState = .loading
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Actions
    
    func fetchUserProfile(userId: Int) {
        Task {
            isLoading = true
            errorMessage = nil
            state = .loading
            
            do {
                let response = try await UserActions.getUserById(userId: userId)
                
                switch response.statusCode {
                case 200:
                    state = .success
                    profileUser = response.value
                    
                default:
                    state = .error
                    errorMessage = "Une erreur est survenue."
                }
            } catch {
                state = .error
                errorMessage = "Impossible de charger le profil."
            }
            
            isLoading = false
        }
    }
    
    func getLikedPosts(id: Int) {
        Task {
            isLoading = true
            errorMessage = nil
            state = .loading
            
            do {
                let response = try await UserActions.getLikedPostsByUser(userId: id)
                
                switch response.statusCode {
                case 200:
                    state = .success
                    likedPosts = response.value
                    
                default:
                    state = .error
                    errorMessage = "Une erreur est survenue."
                }
            } catch {
                state = .error
                errorMessage = "Une erreur est survenue."
            }
            
            isLoading = false
        }
    }
    
    func getPosts(id: Int) {
        Task {
            isLoading = true
            errorMessage = nil
            state = .loading
            
            do {
                let response = try await UserActions.getPostsByUser(userId: id)
                
                switch response.statusCode {
                case 200:
                    state = .success
                    posts = response.value
                    
                default:
                    state = .error
                    errorMessage = "Une erreur est survenue."
                }
            } catch {
                state = .error
                errorMessage = "Une erreur est survenue."
            }
            
            isLoading = false
        }
    }
}




