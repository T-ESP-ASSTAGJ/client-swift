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
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "rectangle.stack.badge.play.fill", value: .home) {
                NavigationStack {
                    HomeView(selectedSegment: $selectedSegment, scrollPosition: $feedScrollPosition)
                }
            }
            
            Tab("Discover", systemImage: "safari", value: .discover) {
                NavigationStack {
                    DiscoverView()
                }
            }
            
            Tab("", systemImage: "plus", value: .create) {
                NavigationStack {
                    CreatePostView()
                }
            }
            
            Tab("Chats", systemImage: "ellipsis.message", value: .chats) {
                NavigationStack {
                    ChatsView()
                }
            }
            
            
            Tab("Profile", systemImage: "person.crop.circle.fill", value: .profile) {
                NavigationStack {
                    ProfileView()
                }
            }
        }
        .accentColor(.white)
    }
}
