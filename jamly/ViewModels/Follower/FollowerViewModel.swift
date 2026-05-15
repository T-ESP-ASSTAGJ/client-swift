//
//  FollowerViewModel.swift
//  jamly
//
//  Created by Jonathan Dumesnil on 31/12/2025.
//

import Foundation
import Combine

/// ViewModel de la liste des followers d'un utilisateur.
///
/// Maintient une pagination par page de 20 entrées. La page courante est exposée pour
/// la UI mais ne doit pas être modifiée de l'extérieur.
@MainActor
final class FollowerViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var followers: [FollowerUser] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var currentPage = 1
    @Published var hasMorePages = true

    // MARK: - Private Properties
    /// Identifiant de l'utilisateur dont on liste les followers, conservé pour les
    /// requêtes de pagination ultérieures.
    private var currentUserId: Int?

    // MARK: - Load Methods

    /// Charge la première page de followers et réinitialise la pagination.
    ///
    /// - Parameter userId: Identifiant de l'utilisateur observé.
    func loadFollowers(userId: Int) async {
        currentUserId = userId
        currentPage = 1
        hasMorePages = true
        followers = []
        errorMessage = nil
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            print("📥 Loading followers for user \(userId), page \(currentPage)")
            let response = try await FollowerAction.getFollowerUsers(
                userId: userId,
                page: currentPage
            )
            
            followers = response.value
            hasMorePages = response.value.count >= 20
            
            print("✅ Loaded \(followers.count) followers")
            print("📄 Has more pages: \(hasMorePages)")
        
            
        } catch {
            errorMessage = "Failed to load followers"
        }
    }
    
    /// Charge la page suivante de followers (infinite scroll).
    ///
    /// En cas d'erreur, ``currentPage`` est restauré pour permettre une nouvelle tentative
    /// sans laisser de trou dans la pagination.
    func loadMoreFollowers() async {
        guard !isLoadingMore, !isLoading, hasMorePages, let userId = currentUserId else {
            print("⚠️ LoadMore blocked - isLoadingMore: \(isLoadingMore), isLoading: \(isLoading), hasMore: \(hasMorePages), userId: \(currentUserId?.description ?? "nil")")
            return
        }
        
        isLoadingMore = true
        errorMessage = nil
        
        do {
            currentPage += 1
            print("📥 Loading MORE followers, page \(currentPage)")
            let response = try await FollowerAction.getFollowerUsers(
                userId: userId,
                page: currentPage
            )
            
            print("✅ Loaded \(response.value.count) more followers")
            followers.append(contentsOf: response.value)
            hasMorePages = response.value.count >= 20
            print("📄 Has more pages: \(hasMorePages)")
            
        } catch {
            errorMessage = "Failed to load more followers: \(error.localizedDescription)"
            print("❌ Error loading more followers: \(error)")
            currentPage -= 1
        }
        
        isLoadingMore = false
    }
}
