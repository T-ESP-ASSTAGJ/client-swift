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
    @State private var selectedPostForDetail: Post?
    @State private var isLoadingPost = false

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
        .sheet(item: $selectedPostForDetail) { post in
            NavigationStack {
                PostDetailView(post: post)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Fermer") {
                                selectedPostForDetail = nil
                            }
                            .foregroundColor(.white)
                        }
                    }
            }
        }
        .overlay {
            if isLoadingPost {
                ZStack {
                    Color.black.opacity(0.5)
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.5)
                        Text("Chargement...")
                            .foregroundColor(.white)
                            .font(.subheadline)
                    }
                }
                .ignoresSafeArea()
            }
        }
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
        .onAppear {
            Task {
                await NotificationManager.shared.resetBadge()
            }
            setupNotificationObservers()
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self)
        }
    }

    // MARK: - Navigation depuis notifications

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .navigateToPost,
            object: nil,
            queue: .main
        ) { notification in
            if let postId = notification.userInfo?["postId"] as? Int {
                print("🚀 Navigation vers le post \(postId)")
                // Pas besoin de changer d'onglet !
                Task {
                    await loadAndNavigateToPost(id: postId)
                }
            }
        }
    }

    // MARK: - Load Post

    private func loadAndNavigateToPost(id: Int) async {
        isLoadingPost = true

        do {
            let response = try await PostActions.fetchPost(id: id)
            selectedPostForDetail = response.value
            print("✅ Post chargé avec succès")
        } catch {
            print("❌ Erreur lors du chargement du post: \(error)")
        }

        isLoadingPost = false
    }
}
