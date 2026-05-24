import SwiftUI
import SwiftData
import Foundation
import Combine
import MusicKit

@main
struct jamlyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var userStore = UserStore()
    @StateObject private var authManager: AuthManager
    @State private var isLoading = true
    
    @StateObject private var musicManager = MusicManager()
    @StateObject private var notificationManager = NotificationManager.shared
    
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        let userStore = UserStore()
        _userStore = StateObject(wrappedValue: userStore)
        _authManager = StateObject(wrappedValue: AuthManager(userStore: userStore))

        // ✅ Supprime les warnings de contraintes AutoLayout (bug iOS)
        UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                if isLoading {
                    SplashScreenView()
                        .transition(.opacity)
                } else {
                    RootView()
                        .environmentObject(authManager)
                        .environmentObject(userStore)
                        .environmentObject(musicManager)
                        .environmentObject(notificationManager)
                }
            }
            .task {
                await userStore.initialize()
                
                // ✅ Demande l'autorisation pour les notifications push
                await notificationManager.requestAuthorization()

                // 📱 Tente de synchroniser le device token (no-op s'il n'est pas encore
                // disponible ou si l'utilisateur n'est pas connecté ; la sync se redéclenchera
                // automatiquement à la réception du token APNs/FCM ou au login).
                notificationManager.syncDeviceTokenIfNeeded()
                
                // ✅ Charge les playlists EN ARRIÈRE-PLAN seulement si déjà autorisé
                await loadMusicIfAuthorized()
            
                await withTaskGroup(of: Void.self) { group in
                    await userStore.loadBothFeeds()
                }
                
                // Délai minimum pour voir le splash screen
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde
                withAnimation(.easeInOut(duration: 0.5)) {
                    isLoading = false
                }
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                switch newPhase {
                case .background:
                    musicManager.pause()
                    print("🎵 App en arrière-plan, musique en pause")
                case .inactive:
                    break
                    
                case .active:
                    // App redevient active → ne fait rien
                    // (la musique reprendra quand l'user retourne sur le feed)
                    print("🎵 App active")
                    // Filet de sécurité : iOS peut rotate le device token, ou la sync au
                    // démarrage peut avoir échoué silencieusement (réseau coupé). On retente.
                    notificationManager.syncDeviceTokenIfNeeded()
                    
                @unknown default:
                    break
                }
            }
        }
    }
    
    // ✅ Charge la musique seulement si déjà autorisé (pas de prompt)
    @MainActor
    private func loadMusicIfAuthorized() async {
        // Vérifie le statut actuel SANS demander l'autorisation
        let currentStatus = await musicManager.checkAuthorizationStatus()
        
        // Si déjà autorisé, marque comme connecté et charge les playlists
        if currentStatus == .authorized {
            print("🎵 Apple Music déjà autorisé, chargement des playlists...")
            musicManager.isConnected = true
            await musicManager.loadPlaylists()
            print("🎵 isConnected = \(musicManager.isConnected), playlists count = \(musicManager.playlists.count)")
        } else {
            print("🎵 Apple Music pas encore autorisé, skip le chargement")
            print("🎵 Status: \(currentStatus)")
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var userStore: UserStore

    var body: some View {
        Group {
            if !authManager.completedOnboarding && !authManager.isAuthenticated {
                OnboardingView()
                    .environmentObject(authManager)
            } else if !authManager.isAuthenticated {
                NavigationStack {
                    LoginView()
                }
            } else if needsProfileSetup {
                ProfileSetupView()
            } else {
                MainTabView()
            }
        }
    }

    private var needsProfileSetup: Bool {
        guard let user = userStore.user else { return false }
        // Photo de profil optionnelle : seul un username vide bloque l'utilisateur sur l'écran
        // de setup. L'app affiche un placeholder (icône person.fill) pour les users sans photo.
        return user.username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
