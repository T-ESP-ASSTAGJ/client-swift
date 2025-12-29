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
    @Published var isLoadingFeed: Bool = false
    @Published var isAuthenticated: Bool = false
    @Published var isLoading = false
    @Published var error: AppError?
    
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
    
    func loadFeed(page: Int = 1, forceRefresh: Bool = false, mode: String = "public") async {
        // ✅ Annule la tâche précédente si elle existe
        feedLoadTask?.cancel()
        
        // Si déjà en cours de chargement et pas de force refresh, ignore
        guard !isLoadingFeed || forceRefresh else {
            print("⏭️ Feed déjà en cours de chargement, skip")
            return
        }
        
        feedLoadTask = Task { @MainActor in
            isLoadingFeed = true
            
            do {
                if(mode == "public") {
                    let response = try await FeedAction.getPublicFeed(page: page)
                    
                    // ✅ Vérifie que la tâche n'a pas été annulée
                    guard !Task.isCancelled else {
                        print("❌ Public feed load cancelled")
                        return
                    }
                    
                    print("ℹ️ Public feed: \(response.value.count) post found !")
                    feed = response.value
                }else if(mode == "private") {
                    let response = try await FeedAction.getPrivateFeed(page: page)
                    
                    // ✅ Vérifie que la tâche n'a pas été annulée
                    guard !Task.isCancelled else {
                        print("❌ Private feed load cancelled")
                        return
                    }
                    
                    print("ℹ️ Private feed: \(response.value.count) post found !")
                    feed = response.value
                }
                
            } catch {
                // Ignore l'erreur si c'est juste une annulation
                guard !Task.isCancelled else {
                    print("❌ Feed load cancelled (error)")
                    return
                }
                
                print("❌ Error loading feed: \(error)")
                feed = []
            }
            
            isLoadingFeed = false
        }
        
        await feedLoadTask?.value
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
