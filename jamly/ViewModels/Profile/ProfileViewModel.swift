//
//  ProfileViewModel.swift
//  jamly
//
//  Created by REVERSS on 30/12/2025.
//

import Foundation
import Combine

/// ViewModel d'une page de profil utilisateur (le sien ou celui d'un autre).
///
/// Agrège plusieurs jeux de données associés au profil :
/// - Informations utilisateur (``profileUser``),
/// - Posts publiés et posts likés, chacun avec leur propre pagination,
/// - Liste des followers (non paginée ici, voir ``FollowerViewModel`` pour la vue dédiée).
@MainActor
final class ProfileViewModel: ObservableObject {
    /// État simple d'une requête de chargement.
    enum VerifyState {
        case loading
        case success
        case error
    }

    @Published var profileUser: User?
    @Published var likedPosts: [Post] = []
    @Published var posts : [Post] = []
    @Published var followers: [FollowerUser] = []
    @Published var following: [FollowingUser] = []
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

    /// Récupère le profil utilisateur par son identifiant.
    ///
    /// - Parameter userId: Identifiant du profil à charger.
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
    
    /// Charge la liste des posts likés par un utilisateur.
    ///
    /// Si `page == 1`, remplace l'état courant ; sinon, ajoute les résultats à la suite.
    ///
    /// - Parameters:
    ///   - id: Identifiant de l'utilisateur observé.
    ///   - page: Numéro de page à charger.
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
    
    /// Charge la page suivante des posts likés (infinite scroll).
    ///
    /// Déduplique sur l'identifiant pour éviter qu'un post ne s'affiche plusieurs fois si
    /// la pagination chevauche après un nouveau like.
    ///
    /// - Parameter userId: Identifiant de l'utilisateur observé.
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
    
    /// Charge la liste des posts publiés par un utilisateur.
    ///
    /// Si `page == 1`, remplace l'état courant ; sinon, ajoute les résultats à la suite.
    ///
    /// - Parameters:
    ///   - id: Identifiant de l'utilisateur observé.
    ///   - page: Numéro de page à charger.
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
    
    /// Charge la page suivante des posts publiés par l'utilisateur (infinite scroll).
    ///
    /// - Parameter userId: Identifiant de l'utilisateur observé.
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
    
    /// Charge la liste des followers d'un utilisateur.
    ///
    /// Cette méthode ne paginerai pas : pour la vue dédiée des followers avec pagination,
    /// utiliser ``FollowerViewModel``.
    ///
    /// - Parameter userId: Identifiant de l'utilisateur observé.
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

    func getFollowing(userId: Int) {
        Task {
            do {
                let response = try await FollowingAction.getFollowingUsers(userId: userId)

                switch response.statusCode {
                case 200:
                    following = response.value

                default:
                    errorMessage = "Une erreur est survenue lors du chargement des following."
                }
            } catch {
                errorMessage = "Impossible de charger les following."
            }
        }
    }
}




