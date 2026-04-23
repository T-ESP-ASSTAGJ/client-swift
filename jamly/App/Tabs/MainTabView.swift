import SwiftUI

enum TabItem: Int, CaseIterable, Hashable {
    case home
    case discover
    case create
    case chats
    case profile
}

struct NotifProfileTarget: Identifiable, Hashable {
    let id: Int
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
    @State private var highlightedCommentId: Int?
    @State private var homeTabPath = NavigationPath()
    @State private var discoverTabPath = NavigationPath()
    @State private var chatsTabPath = NavigationPath()
    @State private var profileTabPath = NavigationPath()

    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var userStore: UserStore
    @EnvironmentObject private var musicManager: MusicManager
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "rectangle.stack.badge.play.fill", value: .home) {
                NavigationStack(path: $homeTabPath) {
                    HomeView(
                        selectedSegment: $selectedSegment,
                        discoveryScrollPosition: $discoveryScrollPosition,
                        friendsScrollPosition: $friendsScrollPosition
                    )
                    .navigationDestination(for: NotifProfileTarget.self) { target in
                        ProfileView(userId: target.id)
                    }
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
                NavigationStack(path: $discoverTabPath) {
                    DiscoverView()
                        .navigationDestination(for: NotifProfileTarget.self) { target in
                            ProfileView(userId: target.id)
                        }
                }
            }

            Tab("", systemImage: "plus", value: .create) {
                CreatePostViewContainer(selectedTab: $selectedTab)
            }

            Tab("Chats", systemImage: "ellipsis.message", value: .chats) {
                NavigationStack(path: $chatsTabPath) {
                    ChatsView()
                        .navigationDestination(for: NotifProfileTarget.self) { target in
                            ProfileView(userId: target.id)
                        }
                }
            }


            Tab("Profile", systemImage: "person.crop.circle.fill", value: .profile) {
                NavigationStack(path: $profileTabPath) {
                    ProfileView()
                        .navigationDestination(for: NotifProfileTarget.self) { target in
                            ProfileView(userId: target.id)
                        }
                }
            }
        }
        .accentColor(.white)
        .sheet(item: $selectedPostForDetail) { post in
            NavigationStack {
                PostDetailView(post: post, highlightedCommentId: highlightedCommentId)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Close") {
                                selectedPostForDetail = nil
                                highlightedCommentId = nil
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
                profileTabPath = NavigationPath()
            }
            if oldValue == .home && newValue != .home {
                musicManager.pause()
                homeTabPath = NavigationPath()
            }
            if oldValue == .discover && newValue != .discover {
                discoverTabPath = NavigationPath()
            }
            if oldValue == .chats && newValue != .chats {
                chatsTabPath = NavigationPath()
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
        }
        .onReceive(NotificationManager.shared.$pendingPostId) { postId in
            guard let postId else { return }
            let commentId = NotificationManager.shared.pendingHighlightedCommentId
            print("🚀 Navigation vers le post \(postId) (commentaire mis en avant: \(commentId.map(String.init) ?? "aucun"))")
            NotificationManager.shared.pendingPostId = nil
            NotificationManager.shared.pendingHighlightedCommentId = nil
            highlightedCommentId = commentId
            Task {
                await loadAndNavigateToPost(id: postId)
            }
        }
        .onReceive(NotificationManager.shared.$pendingProfileUserId) { userId in
            guard let userId else { return }
            print("🚀 Navigation vers profil user \(userId) (tab actuel: \(selectedTab))")
            NotificationManager.shared.pendingProfileUserId = nil
            let target = NotifProfileTarget(id: userId)
            switch selectedTab {
            case .home: homeTabPath.append(target)
            case .discover: discoverTabPath.append(target)
            case .chats: chatsTabPath.append(target)
            case .profile: profileTabPath.append(target)
            case .create: homeTabPath.append(target)
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
