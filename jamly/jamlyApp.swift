import SwiftUI
import SwiftData
import Foundation
import Combine

@main
struct jamlyApp: App {
    @StateObject private var userStore = UserStore()
    @StateObject private var authManager: AuthManager
    @State private var isLoading = true
    
    init() {
        let userStore = UserStore()
        _userStore = StateObject(wrappedValue: userStore)
        _authManager = StateObject(wrappedValue: AuthManager(userStore: userStore))
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
                }
            }
            .task {
                await userStore.initialize()
                // Délai minimum pour voir le splash screen
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 2 secondes
                withAnimation(.easeInOut(duration: 0.5)) {
                    isLoading = false
                }
            }
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
