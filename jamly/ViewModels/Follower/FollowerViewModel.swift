//
//  FollowerViewModel.swift
//  jamly
//
//  Created by Jonathan Dumesnil on 31/12/2025.
//

import Foundation
import Combine

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
    private var currentUserId: Int?
    
    // MARK: - Load Methods
    
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
