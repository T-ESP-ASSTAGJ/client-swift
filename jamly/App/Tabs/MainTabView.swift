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
    @State private var feedScrollPosition: Int?
    @State private var selectedSegment: FeedSegment = .discovery
    
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var userStore: UserStore
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    NavigationStack {
                        // ✅ Passe le binding à HomeFeed
                        HomeView(selectedSegment: $selectedSegment, scrollPosition: $feedScrollPosition)
                    }
                    
                case .discover:
                    NavigationStack {
                        DiscoverView()
                    }
                case .create:
                    NavigationStack {
                        CreatePostView()
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
