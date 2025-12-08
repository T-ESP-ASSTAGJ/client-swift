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
    @Published var isAuthenticated: Bool = false {
        didSet {
            print("🔐 UserStore.isAuthenticated changed to: \(isAuthenticated)")
        }
    }
    @Published var isLoading = false
    @Published var error: AppError?
    
    // MARK: - Dependencies
    private let apiService: APIClient
    private let secureStore: SecureStore
    
    // MARK: - Init
    init(
        apiService: APIClient? = nil,
        secureStore: SecureStore? = nil
    ) {
        print("🔐 UserStore init - Checking token...")
        
        // Resolve dependencies
        self.secureStore = secureStore ?? .shared
        self.apiService = apiService ?? .shared
        
        // Vérifier si un token existe déjà
        self.token = self.secureStore.retrieve()
        
        if self.token != nil {
            self.isAuthenticated = true
            print("🔐 Token found, user authenticated")
        } else {
            print("🔐 No token found")
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
            
            print("😁 CurrentUser: \(String(describing: user))")
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
        secureStore.delete()
    }
    
    /// Initialise le store au démarrage (restaure le token)
    func initialize() async {
        if token != nil {
            await fetchCurrentUser()
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
