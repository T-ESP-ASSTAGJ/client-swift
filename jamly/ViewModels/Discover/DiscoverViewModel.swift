//
//  ProfileViewModel.swift
//  jamly
//
//  Created by REVERSS on 30/12/2025.
//

import Combine
import Foundation

@MainActor
final class DiscoverViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingMorePosts: Bool = false
    @Published var errorMessage: String?

    private var currentPage: Int = 1
    private var hasMorePosts: Bool = true

    // MARK: - Actions

    func getFeedPublic() {
        Task {
            isLoading = true
            errorMessage = nil

            do {
                let response = try await FeedAction.getPublicFeed(page: 1)

                switch response.statusCode {
                case 200:
                    posts = response.value
                    currentPage = 1
                    hasMorePosts = !response.value.isEmpty
                default:
                    errorMessage = "Une erreur est survenue."
                }
            } catch {
                errorMessage = "Impossible de charger le feed public."
            }

            isLoading = false
        }
    }

    func loadMorePosts() {
        guard !isLoadingMorePosts, hasMorePosts else { return }

        Task {
            isLoadingMorePosts = true

            do {
                let nextPage = currentPage + 1
                let response = try await FeedAction.getPublicFeed(page: nextPage)

                switch response.statusCode {
                case 200:
                    let newPosts = response.value

                    if newPosts.isEmpty {
                        hasMorePosts = false
                    } else {
                        let existingIds = Set(posts.map { $0.id })
                        let uniquePosts = newPosts.filter { !existingIds.contains($0.id) }
                        posts.append(contentsOf: uniquePosts)
                        currentPage = nextPage
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
}
