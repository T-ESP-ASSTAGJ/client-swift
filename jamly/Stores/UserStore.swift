//
//  UserStore.swift
//  jamly
//
//  Created by REVERSS on 07/12/2025.
//

import Foundation
import Combine

@MainActor
class UserStore: ObservableObject {
    // MARK: - Published Properties
    @Published var user: User?
    @Published var token: String?
    @Published var feed: [Post] = []
    @Published var discoveryFeed: [Post] = []
    @Published var friendsFeed: [Post] = []
    @Published var isLoadingFeed: Bool = false
    @Published var isLoadingMoreFeed: Bool = false
    @Published var isAuthenticated: Bool = false
    @Published var isLoading = false
    @Published var error: AppError?
    
    // ✅ Cache séparé pour chaque feed
    private var discoveryFeedCache: [Post] = []
    private var friendsFeedCache: [Post] = []
    private var lastLoadedMode: String = "public"
    
    // Pagination
    private var currentDiscoveryPage: Int = 1
    private var currentFriendsPage: Int = 1
    private var hasMoreDiscoveryPosts: Bool = true
    private var hasMoreFriendsPosts: Bool = true
    
    // Track de la tâche de chargement du feed
    private var feedLoadTask: Task<Void, Never>?
    
    // MARK: - Dependencies
    private let apiService: APIClient
    private let secureStore: SecureStore
    
    // MARK: - Init
    init(
        apiService: APIClient? = nil,
        secureStore: SecureStore? = nil
    ) {
        // Resolve dependencies
        self.secureStore = secureStore ?? .shared
        self.apiService = apiService ?? .shared
        
        // Vérifier si un token existe déjà
        self.token = self.secureStore.retrieve()
        
        if self.token != nil {
            self.isAuthenticated = true
        }
        
        // Observer les notifications d'erreur 401
        NotificationCenter.default.addObserver(
            forName: .didReceiveUnauthorized,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleUnauthorized()
            }
        }
    }
    
    // MARK: - Actions
    
    /// Récupère les informations de l'utilisateur actuel
    func fetchCurrentUser() async {
        defer { isLoading = false }
        isLoading = true
        error = nil
        
        do {
            user = try await UserActions.fetchMe().value
            
            print("😀 CurrentUser: \(String(describing: user))")
        } catch let apiError as APIError {
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
        } catch {
            self.error = .unknown
        }
    }
    
    func getCurrentFeed(for segment: FeedSegment) -> [Post] {
        segment == .discovery ? discoveryFeed : friendsFeed
    }
    
    /// Charge les deux feeds en parallèle au démarrage
    func loadBothFeeds() async {
        isLoadingFeed = true
        
        async let publicFeedTask = FeedAction.getPublicFeed(page: 1)
        async let privateFeedTask = FeedAction.getPrivateFeed(page: 1)
        
        do {
            let (publicResponse, privateResponse) = try await (publicFeedTask, privateFeedTask)
            
            discoveryFeed = publicResponse.value
            friendsFeed = privateResponse.value
            discoveryFeedCache = publicResponse.value
            friendsFeedCache = privateResponse.value
            
            // Par défaut on affiche le feed public
            feed = discoveryFeed
            lastLoadedMode = "public"
            
            // Reset pagination
            currentDiscoveryPage = 1
            currentFriendsPage = 1
            hasMoreDiscoveryPosts = true
            hasMoreFriendsPosts = true
            
            print("✅ Both feeds loaded: Discovery(\(discoveryFeed.count)), Friends(\(friendsFeed.count))")
        } catch {
            print("❌ Error loading feeds: \(error)")
            discoveryFeed = []
            friendsFeed = []
            feed = []
        }
        
        isLoadingFeed = false
    }
    
    func loadFeed(page: Int = 1, forceRefresh: Bool = false, mode: String = "public") async {
        // ✅ Si c'est un refresh, recharger depuis l'API
        if forceRefresh {
            feedLoadTask?.cancel()
            
            feedLoadTask = Task { @MainActor in
                isLoadingFeed = true
                
                do {
                    if mode == "public" {
                        let response = try await FeedAction.getPublicFeed(page: page)
                        
                        guard !Task.isCancelled else {
                            print("❌ Public feed refresh cancelled")
                            return
                        }
                        
                        print("🔄 Public feed refreshed: \(response.value.count) posts")
                        discoveryFeed = response.value
                        discoveryFeedCache = response.value
                        feed = response.value
                        currentDiscoveryPage = 1
                        hasMoreDiscoveryPosts = true
                    } else if mode == "private" {
                        let response = try await FeedAction.getPrivateFeed(page: page)
                        
                        guard !Task.isCancelled else {
                            print("❌ Private feed refresh cancelled")
                            return
                        }
                        
                        print("🔄 Private feed refreshed: \(response.value.count) posts")
                        friendsFeed = response.value
                        friendsFeedCache = response.value
                        feed = response.value
                        currentFriendsPage = 1
                        hasMoreFriendsPosts = true
                    }
                } catch {
                    guard !Task.isCancelled else {
                        print("❌ Feed refresh cancelled (error)")
                        return
                    }
                    
                    print("❌ Error refreshing feed: \(error)")
                }
                
                isLoadingFeed = false
            }
            
            await feedLoadTask?.value
            return
        }
        
        // ✅ Sinon, juste switcher entre les feeds en cache
        if mode == "public" {
            feed = discoveryFeed
            lastLoadedMode = "public"
            print("📦 Switched to discovery feed (\(discoveryFeed.count) posts)")
        } else {
            feed = friendsFeed
            lastLoadedMode = "private"
            print("📦 Switched to friends feed (\(friendsFeed.count) posts)")
        }
    }
    
    /// Charge plus de posts pour le feed actuel
    func loadMoreFeed() async {
        // Ne charge pas si on est déjà en train de charger
        guard !isLoadingMoreFeed else {
            print("⚠️ Already loading more posts")
            return
        }
        
        // Vérifie s'il y a encore des posts à charger
        let hasMore = lastLoadedMode == "public" ? hasMoreDiscoveryPosts : hasMoreFriendsPosts
        guard hasMore else {
            print("⚠️ No more posts to load")
            return
        }
        
        isLoadingMoreFeed = true
        
        do {
            if lastLoadedMode == "public" {
                let nextPage = currentDiscoveryPage + 1
                let response = try await FeedAction.getPublicFeed(page: nextPage)
                
                guard !Task.isCancelled else {
                    print("❌ Load more cancelled")
                    isLoadingMoreFeed = false
                    return
                }
                
                let newPosts = response.value
                print("✅ Loaded \(newPosts.count) more discovery posts (page \(nextPage))")
                
                if newPosts.isEmpty {
                    hasMoreDiscoveryPosts = false
                    print("⚠️ No more discovery posts available")
                } else {
                    discoveryFeed.append(contentsOf: newPosts)
                    discoveryFeedCache = discoveryFeed
                    feed = discoveryFeed
                    currentDiscoveryPage = nextPage
                }
            } else {
                let nextPage = currentFriendsPage + 1
                let response = try await FeedAction.getPrivateFeed(page: nextPage)
                
                guard !Task.isCancelled else {
                    print("❌ Load more cancelled")
                    isLoadingMoreFeed = false
                    return
                }
                
                let newPosts = response.value
                print("✅ Loaded \(newPosts.count) more friends posts (page \(nextPage))")
                
                if newPosts.isEmpty {
                    hasMoreFriendsPosts = false
                    print("⚠️ No more friends posts available")
                } else {
                    friendsFeed.append(contentsOf: newPosts)
                    friendsFeedCache = friendsFeed
                    feed = friendsFeed
                    currentFriendsPage = nextPage
                }
            }
        } catch {
            print("❌ Error loading more posts: \(error)")
        }
        
        isLoadingMoreFeed = false
    }
    
    /// Définit le token et sauvegarde en SecureStore
    func setToken(_ token: String) {
        print("🔐 Setting token and authenticating user")
        self.token = token
        secureStore.save(token: token)
        self.isAuthenticated = true
        
        // Notifier le login réussi
        NotificationCenter.default.post(name: .didReceiveAuthorizedLogin, object: nil)
    }
    
    /// Définit l'utilisateur
    func setUser(_ user: User) {
        self.user = user
    }
    
    /// Déconnecte l'utilisateur
    func logout() {
        print("🔐 Logout called")
        user = nil
        token = nil
        isAuthenticated = false
        feed = []
        discoveryFeed = []
        friendsFeed = []
        discoveryFeedCache = []
        friendsFeedCache = []
        lastLoadedMode = "public"
        currentDiscoveryPage = 1
        currentFriendsPage = 1
        hasMoreDiscoveryPosts = true
        hasMoreFriendsPosts = true
        secureStore.delete()
        
        // Annule toute tâche en cours
        feedLoadTask?.cancel()
    }
    
    /// Initialise le store au démarrage (restaure le token)
    func initialize() async {
        if token != nil {
            await fetchCurrentUser()
        }
    }
    
    func followUser(userId: Int) async {
        do {
            _ = try await UserActions.followUser(userId: userId)
            await fetchCurrentUser()
        } catch let apiError as APIError {
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
        } catch {
            self.error = .unknown
        }
    }
    
    func unfollowUser(userId: Int, autoRefresh: Bool = true) async {
        do {
            _ = try await UserActions.unfollowUser(userId: userId)
            if autoRefresh {
                print("test")
                await fetchCurrentUser()
            }
        } catch let apiError as APIError {
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
        } catch {
            self.error = .unknown
        }
    }
    
    func handleUnauthorized() {
        print("🔐 Unauthorized - logging out")
        logout()
        error = .unauthorized
    }
}

// MARK: - Error Type
enum AppError: LocalizedError {
    case unauthorized
    case notFound
    case serverError
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Non autorisé"
        case .notFound:
            return "Non trouvé"
        case .serverError:
            return "Erreur serveur"
        case .networkError:
            return "Erreur réseau"
        case .unknown:
            return "Erreur inconnue"
        }
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let didReceiveAuthorizedLogin = Notification.Name("didReceiveAuthorizedLogin")
    static let didReceiveUnauthorized = Notification.Name("didReceiveUnauthorized")
}
