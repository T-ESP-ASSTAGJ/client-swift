import SwiftUI
import SwiftData
import Foundation
import Combine
import MusicKit

@main
struct jamlyApp: App {
    @StateObject private var userStore = UserStore()
    @StateObject private var authManager: AuthManager
    @State private var isLoading = true
    
    @StateObject private var musicManager = MusicManager()
    
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
                }
            }
            .task {
                await userStore.initialize()
                
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
                case .background, .inactive:
                    // App en arrière-plan ou inactive → pause
                    musicManager.pause()
                    print("🎵 App en arrière-plan, musique en pause")
                    
                case .active:
                    // App redevient active → ne fait rien
                    // (la musique reprendra quand l'user retourne sur le feed)
                    print("🎵 App active")
                    
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

// Vue racine qui gère l'authentification
struct RootView: View {
    @EnvironmentObject private var authManager: AuthManager
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
            } else {
                AuthenticationFlow()
            }
        }
    }
}

// Flow d'authentification avec sa propre navigation
struct AuthenticationFlow: View {
    var body: some View {
        NavigationStack {
            BrandingView()
        }
    }
}
