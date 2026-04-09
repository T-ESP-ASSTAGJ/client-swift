import SwiftUI
import MusicKit

enum ProfileTab: Int, CaseIterable {
    case posts = 0
    case likes = 1
    case stats = 2
}

enum FollowViews: Identifiable {
    var id: String { String(describing: self) }
    case following, followers
}

struct ProfileView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var userStore: UserStore
    @EnvironmentObject var musicManager: MusicManager

    @StateObject private var viewModel = ProfileViewModel()

    /// Si userId est fourni, on affiche le profil d'un autre utilisateur
    let userId: Int?

    @State private var selectedTab: ProfileTab = .posts
    @State private var selectedFollowView: FollowViews? = nil
    @State private var showMusicPlaylists = false
    @State private var showProfileEdit = false
    @State private var selectedPost: Post? = nil
    @State private var isShowingPostDetail = false
    @State private var isFollowingTarget: Bool = false

    // MARK: - Computed Properties

    private var displayedUser: User? {
        userId != nil ? viewModel.profileUser : userStore.user
    }

    private var isOwnProfile: Bool {
        guard let userId, let currentUserId = userStore.user?.id else { return true }
        return userId == currentUserId
    }

    init(userId: Int? = nil) {
        self.userId = userId
    }

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 0) {
                    ProfileHeaderView(user: displayedUser, selectedFollowView: $selectedFollowView)

                    if !isOwnProfile {
                        ProfileFollowButton(
                            isFollowing: isFollowingTarget,
                            onFollow: {
                                Task {
                                    guard let targetUserId = userId else { return }
                                    await userStore.followUser(userId: targetUserId)
                                    isFollowingTarget = true
                                    viewModel.getFollowers(userId: targetUserId)
                                    viewModel.fetchUserProfile(userId: targetUserId)
                                }
                            },
                            onUnfollow: {
                                Task {
                                    guard let targetUserId = userId else { return }
                                    await userStore.unfollowUser(userId: targetUserId, autoRefresh: true)
                                    isFollowingTarget = false
                                    viewModel.getFollowers(userId: targetUserId)
                                    viewModel.fetchUserProfile(userId: targetUserId)
                                }
                            }
                        )
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }

                    GeometryReader { geometry in
                        let minY = geometry.frame(in: .global).minY - 110
                        tabsSection
                            .offset(y: minY < 0 ? -minY : 0)
                            .zIndex(10)
                    }
                    .frame(height: 52)
                    .zIndex(10)

                    TabView(selection: $selectedTab) {
                        postsGrid
                            .tag(ProfileTab.posts)

                        likesGrid
                            .tag(ProfileTab.likes)

                        if isOwnProfile {
                            ProfileStatsView()
                                .tag(ProfileTab.stats)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: calculateGridHeight())
                    .clipped()
                }
            }
            .coordinateSpace(name: "scroll")

            VStack {
                ZStack { }
                    .frame(maxWidth: .infinity)
                    .background(.black)
                Spacer()
            }
        }
        .toolbar {
            if isOwnProfile {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showMusicPlaylists = true
                    } label: {
                        Image(systemName: "music.note.square.stack.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showProfileEdit = true
                    } label: {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                    }
                    .padding(.trailing, 3)

                    Button {
                        authManager.logout()
                    } label: {
                        Image(systemName: "door.right.hand.open")
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .navigationDestination(isPresented: $showMusicPlaylists) {
            MusicPlaylistsView().environmentObject(musicManager)
        }
        .navigationDestination(isPresented: $showProfileEdit) {
            ProfileSettingsMenuView()
        }
        .navigationDestination(item: $selectedFollowView) { view in
            switch view {
            case .followers:
                FollowersView(userId: userId ?? userStore.user?.id)
            case .following:
                FollowingView(userId: userId ?? userStore.user?.id)
            }
        }
        .navigationDestination(isPresented: $isShowingPostDetail) {
            if let post = selectedPost {
                PostDetailView(post: post)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .resetProfileNavigation)) { _ in
            resetNavigation()
        }
        .task {
            if let userId {
                viewModel.fetchUserProfile(userId: userId)
                viewModel.getFollowers(userId: userId)
            }
        }
        .onChange(of: viewModel.followers) { _, newValue in
            guard !isOwnProfile, let currentUserId = userStore.user?.id else { return }
            isFollowingTarget = newValue.contains { $0.id == currentUserId }
        }
    }

    // MARK: - Tabs Section

    private var tabsSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                TabButton(icon: "square.grid.3x3.fill", isSelected: selectedTab == .posts) {
                    selectedTab = .posts
                }
                TabButton(icon: "heart.fill", isSelected: selectedTab == .likes) {
                    selectedTab = .likes
                }
                if isOwnProfile {
                    TabButton(icon: "music.note.list", isSelected: selectedTab == .stats) {
                        selectedTab = .stats
                    }
                }
            }

            GeometryReader { geo in
                let tabWidth = geo.size.width / CGFloat(isOwnProfile ? 3 : 2)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: tabWidth, height: 2)
                    .offset(x: tabWidth * CGFloat(selectedTab.rawValue))
                    .animation(.easeInOut(duration: 0.2), value: selectedTab)
            }
            .frame(height: 2)
        }
        .frame(maxWidth: .infinity)
        .background(Color.black)
    }

    // MARK: - Posts Grid

    private var postsGrid: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                loadingState()
            } else if viewModel.posts.isEmpty {
                emptyState(message: "No posts yet.")
            } else {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(viewModel.posts, id: \.id) { post in
                        gridItem(views: formatNumber(post.viewsCount), cover: post.backImage)
                            .onTapGesture {
                                selectedPost = post
                                isShowingPostDetail = true
                            }
                            .onAppear {
                                if post.id == viewModel.posts.last?.id {
                                    guard let targetUserId = userId ?? userStore.user?.id else { return }
                                    viewModel.loadMorePosts(userId: targetUserId)
                                }
                            }
                    }
                    if viewModel.isLoadingMorePosts {
                        VStack {
                            Spacer()
                            ProgressView().scaleEffect(1.5)
                            Spacer()
                        }
                        .frame(height: 200)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            guard let targetUserId = userId ?? userStore.user?.id else { return }
            viewModel.getPosts(id: targetUserId)
        }
    }

    // MARK: - Likes Grid

    private var likesGrid: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                loadingState()
            } else if viewModel.likedPosts.isEmpty {
                emptyState(message: "No liked posts yet")
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(viewModel.likedPosts, id: \.id) { post in
                            gridItem(views: formatNumber(0), cover: post.backImage)
                                .onTapGesture {
                                    selectedPost = post
                                    isShowingPostDetail = true
                                }
                        }
                        .onAppear {
                            if selectedPost?.id == viewModel.likedPosts.last?.id {
                                guard let targetUserId = userId ?? userStore.user?.id else { return }
                                viewModel.loadMoreLikedPosts(userId: targetUserId)
                            }
                        }
                    }
                    if viewModel.isLoadingMoreLikes {
                        Color.clear
                            .gridCellColumns(3)
                            .overlay { ProgressView().scaleEffect(1.2) }
                            .frame(height: 60)
                    }
                }
            }
        }
        .onAppear {
            guard let targetUserId = userId ?? userStore.user?.id else { return }
            viewModel.getLikedPosts(id: targetUserId)
        }
    }
    // MARK: - Grid Item

    private func gridItem(views: String, cover: String) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                ProfilePostThumbnail(imageURL: cover)
                    .frame(width: geo.size.width, height: geo.size.width)
                    .clipped()

                HStack(spacing: 4) {
                    Image(systemName: "eye.fill").font(.caption)
                    Text(views).font(.caption).bold()
                }
                .foregroundColor(.white)
                .padding(8)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Helpers

    private func emptyState(message: String) -> some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 80)
            Text(message).foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func loadingState() -> some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 80)
            ProgressView()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func calculateGridHeight() -> CGFloat {
        switch selectedTab {
        case .stats:
            // Suffisant pour accueillir la carte + sections dynamiques
            return UIScreen.main.bounds.height * 1.5
        default:
            let itemCount = selectedTab == .posts ? viewModel.posts.count : viewModel.likedPosts.count
            let rowCount = ceil(Double(itemCount) / 3.0)
            let itemHeight = UIScreen.main.bounds.width / 3
            return max(CGFloat(rowCount) * itemHeight + 5, 400)
        }
    }

    private func resetNavigation() {
        selectedFollowView = nil
        isShowingPostDetail = false
        selectedPost = nil
        showMusicPlaylists = false
        showProfileEdit = false
    }
}

// MARK: - Notification

extension Notification.Name {
    static let resetProfileNavigation = Notification.Name("resetProfileNavigation")
}
