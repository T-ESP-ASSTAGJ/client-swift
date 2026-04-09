import SwiftUI

enum TabItem: Int, CaseIterable, Hashable {
    case home
    case discover
    case create
    case chats
    case profile
}

struct MainTabView: View {
    @State private var selectedTab: TabItem = .home
    @State private var discoveryScrollPosition: Int?
    @State private var friendsScrollPosition: Int?
    @State private var selectedSegment: FeedSegment = .discovery

    
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var userStore: UserStore
    @EnvironmentObject private var musicManager: MusicManager
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "rectangle.stack.badge.play.fill", value: .home) {
                NavigationStack {
                    HomeView(
                        selectedSegment: $selectedSegment,
                        discoveryScrollPosition: $discoveryScrollPosition,
                        friendsScrollPosition: $friendsScrollPosition
                    )
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
        .onChange(of: selectedTab) { oldValue, newValue in
            if oldValue == .profile && newValue != .profile {
                NotificationCenter.default.post(name: .resetProfileNavigation, object: nil)
            }
            if oldValue == .home && newValue != .home {
                musicManager.pause()
            }
        }
    }
}
