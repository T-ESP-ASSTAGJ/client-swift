//
//  AuthManager.swift
//  jamly
//
//  Created by REVERSS on 07/12/2025.
//

import Foundation
import Combine

/// Coordinateur d'authentification et d'onboarding exposé à l'arbre SwiftUI.
///
/// `AuthManager` est l'objet observé par ``RootView`` pour décider de l'écran à afficher :
/// onboarding, login ou interface principale. Il synchronise son état avec ``UserStore``
/// via Combine et réagit aux notifications `401` pour forcer le logout.
@MainActor
final class AuthManager: ObservableObject {
    /// Indique si l'utilisateur a déjà parcouru l'onboarding (persisté dans `UserDefaults`).
    @Published var completedOnboarding: Bool = false
    /// Demande explicite d'afficher le tutoriel in-app. Activée uniquement lors d'un
    /// nouveau signup ou via "Replay tutorial" depuis Settings. Désactivée à la fin du tuto.
    @Published var shouldShowTutorial: Bool = false
    /// État d'authentification miroir de ``UserStore/isAuthenticated``.
    @Published var isAuthenticated: Bool = false {
        didSet {
            print("🔐 AuthManager.isAuthenticated changed to: \(isAuthenticated)")
        }
    }

    // MARK: - Dependencies
    private let userStore: UserStore
    private let secureStore: SecureStore
    private var cancellables = Set<AnyCancellable>()

    /// Initialise le gestionnaire et restaure l'état d'authentification.
    ///
    /// - Lit le token depuis ``SecureStore`` pour décider de l'état initial.
    /// - S'abonne à ``UserStore/isAuthenticated`` pour rester synchronisé.
    /// - S'abonne aux notifications `didReceiveUnauthorized` pour forcer un logout.
    ///
    /// - Parameters:
    ///   - userStore: Store partagé contenant l'utilisateur courant.
    ///   - secureStore: Stockage sécurisé. Par défaut ``SecureStore/shared``.
    init(userStore: UserStore, secureStore: SecureStore = .shared) {
        self.userStore = userStore
        self.secureStore = secureStore

        print("🔐 AuthManager init - Checking token...")

        // ⚠️ Le Keychain survit à la désinstallation de l'app (contrairement à UserDefaults).
        // À la première exécution après une (ré)installation, on purge tout token résiduel
        // pour éviter d'entrer dans l'app avec une session fantôme alors qu'on n'est pas connecté.
        let hasLaunchedKey = "jamly.hasLaunchedBefore"
        if !UserDefaults.standard.bool(forKey: hasLaunchedKey) {
            print("🔐 Première exécution après installation → purge du Keychain")
            secureStore.delete()
            UserDefaults.standard.set(true, forKey: hasLaunchedKey)
        }

        // Restaurer l'état onboarding depuis UserDefaults
        self.completedOnboarding = UserDefaults.standard.bool(forKey: "jamly.hasSeenOnboarding")
        self.shouldShowTutorial = UserDefaults.standard.bool(forKey: "jamly.shouldShowTutorial")
        // Vérifier si un token existe déjà dans SecureStore
        if secureStore.retrieve() != nil {
            isAuthenticated = true
            print("🔐 Token found, user authenticated")
        } else {
            print("🔐 No token found")
        }

        // Observer les changements d'authentification du UserStore
        userStore.$isAuthenticated
            .sink { [weak self] isAuth in
                self?.isAuthenticated = isAuth
            }
            .store(in: &cancellables)

        // Observer les notifications d'erreur 401
        NotificationCenter.default.addObserver(
            forName: .didReceiveUnauthorized,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.logout()
        }
    }

    /// Déconnecte l'utilisateur en propageant la déconnexion au ``UserStore``.
    func logout() {
        print("🔐 AuthManager.logout called")
        userStore.logout()
        isAuthenticated = false
        // Sans ça, un autre utilisateur connecté sur le même device ne re-pousserait
        // pas son token (de-dup côté NotificationManager) et resterait invisible côté backend.
        NotificationManager.shared.resetSyncState()
    }

    /// Authentifie l'utilisateur avec le token fourni et déclenche les effets de bord post-login.
    ///
    /// Délègue la persistance du token au ``UserStore`` puis demande à ``NotificationManager``
    /// de synchroniser le device token (no-op s'il n'est pas encore disponible : la sync se
    /// redéclenchera automatiquement à la réception du token APNs/FCM).
    ///
    /// - Parameter token: JWT renvoyé par l'API après authentification.
    func login(token: String) {
        print("🔐 AuthManager.login called")
        userStore.setToken(token)
        isAuthenticated = true
        NotificationManager.shared.syncDeviceTokenIfNeeded()
    }

    /// Marque l'onboarding comme terminé et persiste l'information dans `UserDefaults`
    /// pour éviter de le réafficher au prochain lancement.
    func completeOnboarding() {
        completedOnboarding = true
        UserDefaults.standard.set(true, forKey: "jamly.hasSeenOnboarding")
    }

    /// Active l'affichage du tutoriel. Appelé après un signup réussi (fin de `ProfileSetupView`)
    /// ou depuis le bouton "Replay tutorial" dans Settings.
    func triggerTutorial() {
        shouldShowTutorial = true
        UserDefaults.standard.set(true, forKey: "jamly.shouldShowTutorial")
    }

    /// Marque le tutoriel comme terminé / passé.
    func dismissTutorial() {
        shouldShowTutorial = false
        UserDefaults.standard.set(false, forKey: "jamly.shouldShowTutorial")
    }
}
