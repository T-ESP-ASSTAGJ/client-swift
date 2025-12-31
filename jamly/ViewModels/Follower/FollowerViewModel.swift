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
            let response = try await FollowerAction.getFollowerUsers(
                page: currentPage,
                userId: userId
            )
            
            followers = response.value
            
            print("✅ Loaded followers: \(followers.count) results")
            
        } catch {
            errorMessage = "Failed to load followers"
        }
    }
}
