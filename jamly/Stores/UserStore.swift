//
//  UserStore.swift
//  jamly
//
//  Created by REVERSS on 07/12/2025.
//

import Foundation
import Combine

/// Source de vérité globale pour l'utilisateur connecté, son token et les feeds de posts.
///
/// `UserStore` est injecté dans l'arbre SwiftUI via `@EnvironmentObject` depuis ``jamlyApp``.
/// Il agrège plusieurs responsabilités proches :
/// - Authentification (token, login/logout, gestion des 401),
/// - Profil utilisateur connecté (fetch, mise à jour, suppression de compte),
/// - Feeds Discovery et Friends (chargement, pagination, switch, refresh),
/// - Exposition d'un type d'erreur unifié ``AppError`` consommable par les vues.
///
/// L'annotation `@MainActor` garantit que toutes les mutations des propriétés `@Published`
/// se font sur le main thread, évitant les avertissements de runtime SwiftUI.
@MainActor
class UserStore: ObservableObject {
    // MARK: - Published Properties

    /// Utilisateur actuellement connecté, ou `nil` si non authentifié.
    @Published var user: User?
    /// Token d'authentification présent en mémoire (miroir du Keychain).
    @Published var token: String?
    /// Feed actuellement affiché : alias vers ``discoveryFeed`` ou ``friendsFeed``
    /// selon le segment sélectionné dans la UI.
    @Published var feed: [Post] = []
    /// Posts du feed Discovery (publication publique).
    @Published var discoveryFeed: [Post] = []
    /// Posts du feed Friends (utilisateurs suivis uniquement).
    @Published var friendsFeed: [Post] = []
    /// Indique qu'un chargement complet de feed est en cours (refresh ou initial).
    @Published var isLoadingFeed: Bool = false
    /// Indique qu'une page supplémentaire de feed est en cours de chargement (infinite scroll).
    @Published var isLoadingMoreFeed: Bool = false
    /// `true` dès qu'un token valide est en mémoire ; pilote l'affichage de ``RootView``.
    @Published var isAuthenticated: Bool = false
    /// Indique un chargement générique (profil, update, suppression…).
    @Published var isLoading = false
    /// Dernière erreur normalisée. Reset par les appelants avant chaque action.
    @Published var error: AppError?

    // ✅ Cache séparé pour chaque feed
    /// Cache de la dernière liste Discovery, permettant un switch instantané sans appel réseau.
    private var discoveryFeedCache: [Post] = []
    /// Cache de la dernière liste Friends.
    private var friendsFeedCache: [Post] = []
    /// Dernier segment chargé (`"public"` ou `"private"`), utilisé pour router le chargement
    /// de pages supplémentaires.
    private var lastLoadedMode: String = "public"

    // Pagination
    /// Page actuellement chargée pour le feed Discovery.
    private var currentDiscoveryPage: Int = 1
    /// Page actuellement chargée pour le feed Friends.
    private var currentFriendsPage: Int = 1
    /// `false` quand l'API a renvoyé une page vide pour le feed Discovery : plus rien à charger.
    private var hasMoreDiscoveryPosts: Bool = true
    /// Idem pour le feed Friends.
    private var hasMoreFriendsPosts: Bool = true

    // Track de la tâche de chargement du feed
    /// Tâche de refresh en cours, conservée pour pouvoir l'annuler (pull-to-refresh rapide ou logout).
    private var feedLoadTask: Task<Void, Never>?

    // MARK: - Dependencies
    private let apiService: APIClient
    private let secureStore: SecureStore

    // MARK: - Init

    /// Initialise le store avec ses dépendances et restaure l'état d'authentification.
    ///
    /// Au lancement, le token est lu depuis le Keychain : s'il est présent, l'utilisateur est
    /// considéré comme authentifié (le profil sera chargé par ``initialize()``).
    /// Un observateur est également mis en place pour réagir aux notifications `401`
    /// émises par ``APIClient``.
    ///
    /// - Parameters:
    ///   - apiService: Client HTTP à utiliser. Par défaut ``APIClient/shared``.
    ///   - secureStore: Stockage sécurisé à utiliser. Par défaut ``SecureStore/shared``.
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

    /// Récupère le profil complet de l'utilisateur connecté et met à jour ``user``.
    ///
    /// En cas d'erreur, ``error`` est renseigné avec une valeur ``AppError`` normalisée
    /// que les vues peuvent observer pour afficher une alerte.
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
    
    /// Retourne la liste de posts associée au segment demandé sans modifier l'état.
    ///
    /// - Parameter segment: Le segment de feed (`.discovery` ou `.friends`).
    /// - Returns: La liste de posts cachée pour ce segment.
    func getCurrentFeed(for segment: FeedSegment) -> [Post] {
        segment == .discovery ? discoveryFeed : friendsFeed
    }

    /// Charge les deux feeds (Discovery et Friends) en parallèle au démarrage de l'app.
    ///
    /// Initialise les caches et la pagination, puis affiche le feed Discovery par défaut.
    /// Cette méthode est appelée par ``jamlyApp`` après l'authentification pour éviter un
    /// délai supplémentaire lors du premier switch de segment.
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
    
    /// Charge ou bascule sur un feed selon le mode et le drapeau de rafraîchissement.
    ///
    /// - Lorsque `forceRefresh == true`, recharge le feed depuis l'API et remplace le cache.
    ///   Toute requête en cours est annulée pour éviter les écrasements concurrents.
    /// - Lorsque `forceRefresh == false`, se contente de basculer ``feed`` sur le cache
    ///   approprié, sans appel réseau.
    ///
    /// - Parameters:
    ///   - page: Page à charger en cas de refresh. Par défaut `1` (début du feed).
    ///   - forceRefresh: Si `true`, force un appel réseau. Sinon, switch sur le cache.
    ///   - mode: `"public"` pour Discovery, `"private"` pour Friends.
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
    
    /// Charge la page suivante du feed actuellement affiché (infinite scroll).
    ///
    /// Garantit qu'un seul chargement de page supplémentaire est en cours à la fois.
    /// Une réponse vide marque la fin du feed (``hasMoreDiscoveryPosts`` ou
    /// ``hasMoreFriendsPosts`` passe à `false`) et empêche tout appel ultérieur.
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
    
    /// Définit le token d'authentification et persiste l'utilisateur comme connecté.
    ///
    /// Le token est sauvegardé dans le Keychain via ``SecureStore``, et une notification
    /// `.didReceiveAuthorizedLogin` est postée pour permettre à d'autres parties de l'app
    /// (notifications push, Mercure…) de réagir au login.
    ///
    /// - Parameter token: Le JWT renvoyé par le serveur après authentification.
    func setToken(_ token: String) {
        print("🔐 Setting token and authenticating user")
        self.token = token
        secureStore.save(token: token)
        self.isAuthenticated = true
        
        // Notifier le login réussi
        NotificationCenter.default.post(name: .didReceiveAuthorizedLogin, object: nil)
    }
    
    /// Remplace le profil utilisateur courant.
    ///
    /// Utilisé après une mise à jour côté serveur pour rafraîchir l'état local sans
    /// déclencher un nouveau `fetch`.
    ///
    /// - Parameter user: Le profil mis à jour.
    func setUser(_ user: User) {
        self.user = user
    }

    /// Déconnecte l'utilisateur et nettoie tout l'état local.
    ///
    /// Vide les feeds et leurs caches, réinitialise la pagination, supprime le token du
    /// Keychain et annule la tâche de chargement de feed en cours.
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
    
    /// Initialise le store au démarrage de l'app.
    ///
    /// Si un token a été restauré depuis le Keychain, déclenche la récupération du profil
    /// utilisateur. À appeler une seule fois, idéalement depuis le `.task` racine.
    func initialize() async {
        if token != nil {
            await fetchCurrentUser()
        }
    }

    /// Suit un utilisateur et rafraîchit le profil courant pour mettre à jour les compteurs.
    ///
    /// - Parameter userId: Identifiant de l'utilisateur à suivre.
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
    
    /// Cesse de suivre un utilisateur.
    ///
    /// - Parameters:
    ///   - userId: Identifiant de l'utilisateur à ne plus suivre.
    ///   - autoRefresh: Si `true`, recharge le profil courant pour synchroniser les compteurs.
    ///     Mettre à `false` quand on enchaîne plusieurs unfollow rapides afin d'éviter
    ///     un fetch par appel.
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
    
    /// Met à jour le profil de l'utilisateur connecté.
    ///
    /// Tous les paramètres sont optionnels : seuls les champs non-`nil` sont envoyés à l'API
    /// (équivalent d'un `PATCH` partiel).
    ///
    /// - Parameters:
    ///   - username: Nouveau nom d'utilisateur, ou `nil` pour le laisser inchangé.
    ///   - phoneNumber: Nouveau numéro de téléphone.
    ///   - bio: Nouvelle biographie.
    ///   - profilePicture: Nouvelle URL de photo de profil.
    /// - Returns: `true` si la mise à jour a réussi, `false` sinon. ``error`` est renseigné
    ///   en cas d'échec.
    func updateProfile(username: String?, phoneNumber: String?, bio: String?, profilePicture: String?) async -> Bool {
        defer { isLoading = false }
        isLoading = true
        error = nil
        
        do {
            let response = try await UserActions.updateProfile(
                username: username,
                phoneNumber: phoneNumber,
                bio: bio,
                profilePicture: profilePicture
            )
            
            user = response.value
            return true
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
            return false
        } catch {
            self.error = .unknown
            return false
        }
    }
    
    /// Supprime définitivement le compte de l'utilisateur connecté.
    ///
    /// En cas de succès, ``logout()`` est appelée pour nettoyer entièrement l'état local.
    ///
    /// - Returns: `true` si la suppression a abouti, `false` en cas d'erreur
    ///   (utilisateur non chargé, échec serveur…).
    func deleteAccount() async -> Bool {
        defer { isLoading = false }
        isLoading = true
        error = nil
        
        // Get user ID before deletion
        guard let userId = user?.id else {
            error = .unknown
            return false
        }
        
        do {
            _ = try await UserActions.deleteAccount(userId: userId)
            
            // Log out the user after successful deletion
            logout()
            return true
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
            return false
        } catch {
            self.error = .unknown
            return false
        }
    }
    
    /// Réaction à une notification `401` postée par ``APIClient``.
    ///
    /// Déclenche un logout complet et positionne ``error`` à ``AppError/unauthorized``
    /// pour que la vue racine bascule vers l'écran de login.
    func handleUnauthorized() {
        print("🔐 Unauthorized - logging out")
        logout()
        error = .unauthorized
    }
}

// MARK: - Error Type

/// Erreur normalisée exposée par ``UserStore`` aux vues.
///
/// Sert d'intermédiaire entre les erreurs typées ``APIError`` (techniques) et l'UI
/// qui n'a besoin que de catégories sémantiques pour afficher un message.
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
    /// Postée par ``UserStore/setToken(_:)`` lorsqu'un login aboutit. Consommée par les services
    /// qui doivent s'initialiser à ce moment (notifications push, abonnement Mercure…).
    static let didReceiveAuthorizedLogin = Notification.Name("didReceiveAuthorizedLogin")
    /// Postée par ``APIClient`` lorsqu'une réponse `401` est reçue, déclenchant le logout
    /// via ``UserStore/handleUnauthorized()``.
    static let didReceiveUnauthorized = Notification.Name("didReceiveUnauthorized")
}
