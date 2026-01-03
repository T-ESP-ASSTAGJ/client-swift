//
//  FollowingViewModel.swift
//  jamly
//
//  Created by Jonathan Dumesnil on 31/12/2025.
//

import Foundation
import Combine

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
    
    /// Load following users for a user (resets pagination)
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
                userId: userId
            )
            
            followingUsers = response.value
            
            print("✅ Loaded following: \(followingUsers.count) results")
            
        } catch {
            errorMessage = "Failed to load following"
        }
    }
}
