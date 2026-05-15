//
//  SearchViewModel.swift
//  jamly
//
//  Created by Alexandre Vandenbulcke on 30/12/2025.
//

import Foundation
import SwiftUI
import Combine

/// ViewModel de la recherche d'utilisateurs.
///
/// Gère la pagination, l'annulation des recherches obsolètes (debouncing implicite via
/// `Task.cancel()`) et la normalisation des erreurs vers ``AppError``.
@MainActor
class SearchViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var searchResults: [SearchUser] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var error: AppError?
    @Published var currentPage = 1
    @Published var hasMorePages = true
    /// Dernière requête saisie ; conservée pour la pagination ultérieure.
    @Published var currentSearchQuery = ""

    // MARK: - Private Properties
    /// Tâche de recherche en cours, conservée pour pouvoir être annulée si une nouvelle
    /// recherche est lancée avant la fin de la précédente.
    private var searchTask: Task<Void, Never>?
    private let itemsPerPage = 20 // Adjust based on your API

    // MARK: - Search Methods

    /// Lance une nouvelle recherche en réinitialisant la pagination.
    ///
    /// Toute recherche précédente est annulée pour éviter qu'une réponse tardive ne vienne
    /// écraser les résultats d'une requête plus récente.
    ///
    /// - Parameter query: Texte saisi par l'utilisateur ; une chaîne vide vide les résultats.
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
    
    /// Charge la page suivante de résultats pour la requête courante.
    ///
    /// Ne fait rien si une page est déjà en cours de chargement, s'il n'y a plus de page,
    /// ou si aucune requête n'est active.
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
    
    /// Indique si l'apparition à l'écran d'un utilisateur donné doit déclencher
    /// le chargement de la page suivante.
    ///
    /// La règle de prefetch est la même que pour les autres listes paginées : on déclenche
    /// quand on est à 3 entrées de la fin.
    ///
    /// - Parameter user: Utilisateur en train de s'afficher.
    /// - Returns: `true` si le seuil de prefetch est atteint.
    func shouldLoadMore(for user: SearchUser) -> Bool {
        // Load more when user scrolls to the last 3 items
        guard let lastUser = searchResults.suffix(3).first else {
            return false
        }
        return user.id == lastUser.id
    }
    
    /// Annule la recherche en cours et remet tout l'état à zéro.
    ///
    /// À appeler lors de la fermeture de la barre de recherche ou d'un changement d'écran.
    func clearResults() {
        searchTask?.cancel()
        searchResults = []
        currentPage = 1
        hasMorePages = true
        currentSearchQuery = ""
        error = nil
    }
    
    // MARK: - Error Handling

    /// Convertit une ``APIError`` en ``AppError`` consommable par les vues.
    ///
    /// - Parameter apiError: Erreur typée renvoyée par ``APIClient``.
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
