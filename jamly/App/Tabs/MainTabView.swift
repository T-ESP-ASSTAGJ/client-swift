import SwiftUI

enum TabItem: Int, CaseIterable, Hashable {
    case home
    case discover
    case create
    case chats
    case profile
}

// Container pour gérer la navigation du CreatePostView
struct CreatePostViewContainer: View {
    @Binding var selectedTab: TabItem
    
    var body: some View {
        NavigationStack {
            CreatePostView(selectedTab: $selectedTab)
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: TabItem = .home
    @State private var discoveryScrollPosition: Int?
    @State private var friendsScrollPosition: Int?
    @State private var selectedSegment: FeedSegment = .discovery
    @State private var shouldRefreshDiscovery = false

    
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
                .onChange(of: shouldRefreshDiscovery) { oldValue, newValue in
                    if newValue {
                        // Reset to first post
                        if let firstPost = userStore.feed.first {
                            discoveryScrollPosition = firstPost.id
                        }
                        shouldRefreshDiscovery = false
                    }
                }
            }
            
            Tab("Discover", systemImage: "safari", value: .discover) {
                NavigationStack {
                    DiscoverView()
                }
            }
            
            Tab("", systemImage: "plus", value: .create) {
                CreatePostViewContainer(selectedTab: $selectedTab)
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
            
            if oldValue == .create && newValue == .home {
                selectedSegment = .discovery
                shouldRefreshDiscovery = true
            }
        }
    }
}
