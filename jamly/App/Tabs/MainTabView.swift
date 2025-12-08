import SwiftUI

enum TabItem: Int, CaseIterable {
    case home
    case discover
    case create
    case chats
    case profile
}

struct MainTabView: View {
    @State private var selectedTab: TabItem = .home
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var userStore: UserStore
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Contenu selon l'onglet sélectionné
            // ✅ Chaque tab a son propre NavigationStack
            Group {
                switch selectedTab {
                case .home:
                    NavigationStack {
                        HomeView()
                    }
                    
                case .discover:
                    NavigationStack {
                        DiscoverView()
                    }
                    
                case .create:
                    NavigationStack {
                        CreateView()
                    }
                    
                case .chats:
                    NavigationStack {
                        ChatsView()
                    }
                    
                case .profile:
                    NavigationStack {
                        ProfileView()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // TabBar custom
            TabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

struct CreateView: View {
    var body: some View {
        VStack {
            Text("Create Content")
                .font(.largeTitle)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Create")
    }
}

// Vues de détail
struct SearchView: View {
    var body: some View {
        Text("Search Results")
            .foregroundColor(.white)
            .navigationTitle("Search")
    }
}

struct ChatDetailView: View {
    let chatName: String
    
    var body: some View {
        VStack {
            Text("Chat with \(chatName)")
                .foregroundColor(.white)
        }
        .navigationTitle(chatName)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthManager(userStore: UserStore()))
        .environmentObject(UserStore())
}
