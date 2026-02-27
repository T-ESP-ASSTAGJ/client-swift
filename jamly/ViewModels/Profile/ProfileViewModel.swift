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
    @Published var followers: [FollowerUser] = []
    @Published var state: VerifyState = .loading
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isLoadingMoreLikes: Bool = false
    @Published var isLoadingMorePosts: Bool = false
    @Published var currentLikesPage: Int = 1
    @Published var currentPostsPage: Int = 1
    @Published var hasMoreLikedPosts: Bool = true
    @Published var hasMoreUserPosts: Bool = true
    
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
    
    func getLikedPosts(id: Int, page: Int = 1) {
        Task {
            isLoading = true
            errorMessage = nil
            state = .loading
            
            do {
                let response = try await UserActions.getLikedPostsByUser(userId: id, page: page)
                
                switch response.statusCode {
                case 200:
                    state = .success
                    if page == 1 {
                        likedPosts = response.value
                        currentLikesPage = 1
                        hasMoreLikedPosts = true
                    } else {
                        likedPosts.append(contentsOf: response.value)
                    }
                    
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
    
    func loadMoreLikedPosts(userId: Int) {
        guard !isLoadingMoreLikes, hasMoreLikedPosts else {
            print("⚠️ Already loading or no more liked posts")
            return
        }
        
        Task {
            isLoadingMoreLikes = true
            
            do {
                let nextPage = currentLikesPage + 1
                let response = try await UserActions.getLikedPostsByUser(userId: userId, page: nextPage)
                
                switch response.statusCode {
                case 200:
                    let newPosts = response.value
                    print("✅ Loaded \(newPosts.count) more liked posts (page \(nextPage))")
                    
                    if newPosts.isEmpty {
                        hasMoreLikedPosts = false
                        print("⚠️ No more liked posts available")
                    } else {
                        // Filtrer les doublons avant d'ajouter
                        let existingIds = Set(likedPosts.map { $0.id })
                        let uniqueNewPosts = newPosts.filter { !existingIds.contains($0.id) }
                        
                        if uniqueNewPosts.count != newPosts.count {
                            print("⚠️ Warning: \(newPosts.count - uniqueNewPosts.count) duplicate liked posts filtered")
                        }
                        
                        likedPosts.append(contentsOf: uniqueNewPosts)
                        currentLikesPage = nextPage
                    }
                    
                default:
                    errorMessage = "Une erreur est survenue lors du chargement."
                }
            } catch {
                errorMessage = "Impossible de charger plus de posts."
            }
            
            isLoadingMoreLikes = false
        }
    }
    
    func getPosts(id: Int, page: Int = 1) {
        Task {
            isLoading = true
            errorMessage = nil
            state = .loading
            
            do {
                let response = try await UserActions.getPostsByUser(userId: id, page: page)
                
                switch response.statusCode {
                case 200:
                    state = .success
                    if page == 1 {
                        posts = response.value
                        currentPostsPage = 1
                        hasMoreUserPosts = true
                    } else {
                        posts.append(contentsOf: response.value)
                    }
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
    
    func loadMorePosts(userId: Int) {
        guard !isLoadingMorePosts, hasMoreUserPosts else {
            print("⚠️ Already loading or no more posts")
            return
        }
        
        Task {
            isLoadingMorePosts = true
            
            do {
                let nextPage = currentPostsPage + 1
                let response = try await UserActions.getPostsByUser(userId: userId, page: nextPage)
                
                switch response.statusCode {
                case 200:
                    let newPosts = response.value
                    print("✅ Loaded \(newPosts.count) more posts (page \(nextPage))")
                    
                    if newPosts.isEmpty {
                        hasMoreUserPosts = false
                        print("⚠️ No more liked posts available")
                    } else {
                        // Filtrer les doublons avant d'ajouter
                        let existingIds = Set(posts.map { $0.id })
                        let uniqueNewPosts = newPosts.filter { !existingIds.contains($0.id) }
                        
                        if uniqueNewPosts.count != newPosts.count {
                            print("⚠️ Warning: \(newPosts.count - uniqueNewPosts.count) duplicate liked posts filtered")
                        }
                        
                        posts.append(contentsOf: uniqueNewPosts)
                        currentPostsPage = nextPage
                    }
                    
                default:
                    errorMessage = "Une erreur est survenue lors du chargement."
                }
            } catch {
                errorMessage = "Impossible de charger plus de posts."
            }
            
            isLoadingMorePosts = false
        }
    }
    
    func getFollowers(userId: Int) {
        Task {
            do {
                let response = try await FollowerAction.getFollowerUsers(userId: userId)
                
                switch response.statusCode {
                case 200:
                    followers = response.value
                    
                default:
                    errorMessage = "Une erreur est survenue lors du chargement des followers."
                }
            } catch {
                errorMessage = "Impossible de charger les followers."
            }
        }
    }
}




