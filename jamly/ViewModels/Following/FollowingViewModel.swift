//
//  FollowingViewModel.swift
//  jamly
//
//  Created by Jonathan Dumesnil on 31/12/2025.
//

import Foundation
import Combine

/// ViewModel de la liste des utilisateurs suivis (followings) par un utilisateur.
///
/// Pendant logique de ``FollowerViewModel`` : pagination de 20 entrées, état d'erreur dédié,
/// et identifiant utilisateur mémorisé pour la pagination.
@MainActor
final class FollowingViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var followingUsers: [FollowingUser] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var currentPage = 1
    @Published var hasMorePages = true

    // MARK: - Private Properties
    private let itemsPerPage = 20
    private var currentUserId: Int?

    // MARK: - Load Methods

    /// Charge la première page d'utilisateurs suivis et réinitialise la pagination.
    ///
    /// - Parameter userId: Identifiant de l'utilisateur observé.
    func loadFollowing(userId: Int) async {
        currentUserId = userId
        currentPage = 1
        hasMorePages = true
        followingUsers = []
        errorMessage = nil
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response = try await FollowingAction.getFollowingUsers(
                userId: userId,
                page: currentPage
            )
            
            followingUsers = response.value
            hasMorePages = response.value.count >= 20
            
            print("✅ Loaded following: \(followingUsers.count) results")
            
        } catch {
            errorMessage = "Failed to load following"
        }
    }
    
    /// Charge la page suivante des utilisateurs suivis (infinite scroll).
    ///
    /// En cas d'erreur, ``currentPage`` est restauré pour permettre une nouvelle tentative.
    func loadMoreFollowing() async {
        guard !isLoadingMore, !isLoading, hasMorePages, let userId = currentUserId else {
            print("⚠️ LoadMore blocked - isLoadingMore: \(isLoadingMore), isLoading: \(isLoading), hasMore: \(hasMorePages), userId: \(currentUserId?.description ?? "nil")")
            return
        }
        
        isLoadingMore = true
        errorMessage = nil
        
        do {
            currentPage += 1
            print("📥 Loading MORE following, page \(currentPage)")
            let response = try await FollowingAction.getFollowingUsers(
                userId: userId,
                page: currentPage
            )
            
            print("✅ Loaded \(response.value.count) more following")
            followingUsers.append(contentsOf: response.value)
            hasMorePages = response.value.count >= itemsPerPage
            print("📄 Has more pages: \(hasMorePages)")
            
        } catch {
            errorMessage = "Failed to load more following: \(error.localizedDescription)"
            print("❌ Error loading more following: \(error)")
            currentPage -= 1
        }
        
        isLoadingMore = false
    }
}
