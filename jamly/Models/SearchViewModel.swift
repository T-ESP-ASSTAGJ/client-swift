//
//  SearchViewModel.swift
//  jamly
//
//  Created by Alexandre Vandenbulcke on 30/12/2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class SearchViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var searchResults: [SearchUser] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var error: AppError?
    @Published var currentPage = 1
    @Published var hasMorePages = true
    @Published var currentSearchQuery = ""
    
    // MARK: - Private Properties
    private var searchTask: Task<Void, Never>?
    private let itemsPerPage = 20 // Adjust based on your API
    
    // MARK: - Search Methods
    
    /// Perform a new search (resets pagination)
    func search(query: String) async {
        // Cancel any ongoing search
        searchTask?.cancel()
        
        // Reset state for new search
        currentSearchQuery = query
        currentPage = 1
        hasMorePages = true
        searchResults = []
        error = nil
        
        guard !query.isEmpty else {
            return
        }
        
        searchTask = Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                let response = try await SearchAction.searchUsers(username: query, page: currentPage)
                
                // Check if task was cancelled
                guard !Task.isCancelled else { return }
                
                searchResults = response.value
                
                // Check if there are more pages
                // If we got less than itemsPerPage, we're at the end
                hasMorePages = response.value.count >= itemsPerPage
                
                print("✅ Search completed: \(searchResults.count) results")
                
            } catch let apiError as APIError {
                guard !Task.isCancelled else { return }
                handleAPIError(apiError)
            } catch {
                guard !Task.isCancelled else { return }
                self.error = .unknown
            }
        }
        
        await searchTask?.value
    }
    
    /// Load next page of results
    func loadMoreResults() async {
        // Prevent multiple simultaneous loads
        guard !isLoadingMore,
              !isLoading,
              hasMorePages,
              !currentSearchQuery.isEmpty else {
            return
        }
        
        isLoadingMore = true
        defer { isLoadingMore = false }
        
        let nextPage = currentPage + 1
        
        do {
            let response = try await SearchAction.searchUsers(
                username: currentSearchQuery,
                page: nextPage
            )
            
            // Check if we got results
            if !response.value.isEmpty {
                searchResults.append(contentsOf: response.value)
                currentPage = nextPage
                
                // Check if there are more pages
                hasMorePages = response.value.count >= itemsPerPage
                
                print("✅ Loaded page \(nextPage): \(response.value.count) more results")
            } else {
                hasMorePages = false
                print("ℹ️ No more results to load")
            }
            
        } catch let apiError as APIError {
            handleAPIError(apiError)
        } catch {
            self.error = .unknown
        }
    }
    
    /// Check if we should load more when a user appears
    func shouldLoadMore(for user: SearchUser) -> Bool {
        // Load more when user scrolls to the last 3 items
        guard let lastUser = searchResults.suffix(3).first else {
            return false
        }
        return user.id == lastUser.id
    }
    
    /// Clear all search results
    func clearResults() {
        searchTask?.cancel()
        searchResults = []
        currentPage = 1
        hasMorePages = true
        currentSearchQuery = ""
        error = nil
    }
    
    // MARK: - Error Handling
    
    private func handleAPIError(_ apiError: APIError) {
        switch apiError {
        case .unauthorized:
            error = .unauthorized
        case .networkError:
            error = .networkError
        case .serverError:
            error = .serverError
        default:
            error = .unknown
        }
    }
}
