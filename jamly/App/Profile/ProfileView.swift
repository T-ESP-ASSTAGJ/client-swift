import SwiftUI

enum ProfileTab: Int, CaseIterable {
    case posts = 0
    case likes = 1
    case music = 2
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
    
    // MARK: - Profile Mode
    /// Si userId est fourni, on affiche le profil d'un autre utilisateur
    /// Sinon, on affiche le profil de l'utilisateur connecté
    let userId: Int?

    @State private var selectedTab: ProfileTab = .posts
    @State private var selectedFollowView: FollowViews? = nil
    @State private var showMusicPlaylists = false
    @State private var selectedPost: Post? = nil
    @State private var isShowingPostDetail = false
    @State private var isFollowingTarget: Bool = false
    
    // MARK: - Computed Properties

    /// Retourne l'utilisateur à afficher (celui du profil visité ou le user connecté)
    private var displayedUser: User? {
        if userId != nil {
            return viewModel.profileUser
        } else {
            return userStore.user
        }
    }

    /// Indique si on affiche son propre profil
    private var isOwnProfile: Bool {
        guard let userId = userId, let currentUserId = userStore.user?.id else {
            return true // Par défaut, c'est notre profil
        }
        return userId == currentUserId
    }

    // MARK: - Init

    init(userId: Int? = nil) {
        self.userId = userId
    }

    let photos = [
        ("photo1", "661K"),
        ("photo2", "97K"),
        ("photo3", "808K"),
        ("photo4", "373K"),
        ("photo5", "581K"),
        ("photo6", "768K"),
        ("photo7", "640K"),
        ("photo8", "62K"),
        ("photo9", "916K"),
        ("photo10", "276K"),
        ("photo11", "26K"),
        ("photo12", "2K"),
    ]
    
    let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 0) {
                    // Header (photo de profil et infos)
                    headerSection
                    
                    // Follow/Unfollow button (seulement si ce n'est pas notre profil)
                    if !isOwnProfile {
                        followButtonSection
                            .padding(.horizontal)
                            .padding(.bottom, 16)
                    }

                    // Tabs avec GeometryReader pour sticky
                    GeometryReader { geometry in
                        let minY = geometry.frame(in: .global).minY - 110
                        
                        tabsSection
                            .offset(y: minY < 0 ? -minY : 0)
                            .zIndex(10)
                    }
                    .frame(height: 52)
                    .zIndex(10)
                    
                    // Pager Content
                    TabView(selection: $selectedTab) {
                        // MARK: - Posts Tab
                        postsGrid
                            .tag(ProfileTab.posts)
                        
                        // MARK: - Likes Tab
                        likesGrid
                            .tag(ProfileTab.likes)
                        
                        // MARK: - Music Tab
                        if isOwnProfile {
                            musicGrid
                                .tag(ProfileTab.music)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: calculateGridHeight())
                }
            }
            .coordinateSpace(name: "scroll")
            
            // Top bar background
            VStack {
                ZStack { }
                    .frame(maxWidth: .infinity)
                    .background(.black)
                Spacer()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // N'afficher le bouton musique que sur son propre profil
                if isOwnProfile {
                    Button {
                        showMusicPlaylists = true
                    } label: {
                        Image(systemName: "music.note.square.stack.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                    }
                    .padding(.trailing, 3)
                }
            }
        }
        .navigationDestination(isPresented: $showMusicPlaylists) {
            MusicPlaylistsView()
                .environmentObject(musicManager)
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
            } else {
                EmptyView()
            }
        }
        .task {
            // Charger le profil si c'est un autre utilisateur
            if let userId = userId {
                viewModel.fetchUserProfile(userId: userId)
                // Charger les followers pour vérifier si on suit déjà cet utilisateur
                viewModel.getFollowers(userId: userId)
            }
        }
        .onChange(of: viewModel.followers) { oldValue, newValue in
            // Vérifier si l'utilisateur connecté est dans les followers
            if !isOwnProfile, let currentUserId = userStore.user?.id {
                isFollowingTarget = newValue.contains(where: { $0.id == currentUserId })
            }
        }
    }
    
    // MARK: - Tabs Section (Sticky)
    private var tabsSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                TabButton(
                    icon: "square.grid.3x3.fill",
                    isSelected: selectedTab == .posts
                ) {
                    selectedTab = .posts
                }
                
                TabButton(
                    icon: "heart.fill",
                    isSelected: selectedTab == .likes
                ) {
                    selectedTab = .likes
                }
                
                if isOwnProfile {
                    TabButton(
                        icon: "music.note.list",
                        isSelected: selectedTab == .music
                    ) {
                        selectedTab = .music
                    }
                }
            }
            
            // Indicateur animé
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
                        gridItem(views: formatNumber(0), cover: post.backImage)
                            .onTapGesture {
                                selectedPost = post
                                isShowingPostDetail = true
                            }
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
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(viewModel.likedPosts, id: \.id) { post in
                        gridItem(views: "0", cover: post.backImage)
                            .onTapGesture {
                                selectedPost = post
                                isShowingPostDetail = true
                            }
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            guard let targetUserId = userId ?? userStore.user?.id else { return }
            viewModel.getLikedPosts(id: targetUserId)
        }
    }
    
    // MARK: - Music Grid
    private var musicGrid: some View {
        VStack(spacing: 0) {
            emptyState(message: "No music yet")
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    // MARK: - Grid Item
    private func gridItem(views: String, cover: String) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: URL(string: cover)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.width)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay {
                            ProgressView()
                        }
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "eye.fill")
                        .font(.caption)
                    Text(views)
                        .font(.caption)
                        .bold()
                }
                .foregroundColor(.white)
                .padding(8)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    // MARK: - Empty State
    private func emptyState(message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
                .frame(height: 80)
            
            Text(message)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Loading State
    private func loadingState() -> some View {
        VStack(spacing: 12) {
            Spacer()
                .frame(height: 80)
            
            ProgressView()
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Calculate Grid Height
    private func calculateGridHeight() -> CGFloat {
        let itemCount: Int
        switch selectedTab {
        case .posts:
            itemCount = viewModel.posts.count
        case .likes:
            itemCount = viewModel.likedPosts.count
        case .music:
            itemCount = 0 // Pas de musique pour l'instant
        }
        let rowCount = ceil(Double(itemCount) / 3.0)
        let screenWidth = UIScreen.main.bounds.width
        let itemHeight = screenWidth / 3
        return max(CGFloat(rowCount) * itemHeight + 5, 400)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    if let user = displayedUser, let profilePicture = user.profilePicture {
                        AsyncImage(url: URL(string: profilePicture)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 85, height: 85)
                                .clipShape(Circle())
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 85, height: 85)
                                .overlay {
                                    ProgressView()
                                }
                        }
                    } else {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            .frame(width: 85, height: 85)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 35))
                                    .foregroundColor(.gray)
                            }
                    }
                }
                .padding(.vertical)
                .padding(.horizontal, 7)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(displayedUser?.username ?? "")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("@\(displayedUser?.username ?? "")")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            
            HStack(spacing: 20) {
                Button {
                    selectedFollowView = .following
                } label: {
                    StatView(
                        number: formatNumber(displayedUser?.followingCount ?? 0),
                        label: "Following"
                    )
                }
                
                VStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 1, height: 25)
                
                Button {
                    selectedFollowView = .followers
                } label: {
                    StatView(
                        number: formatNumber(displayedUser?.followersCount ?? 0),
                        label: "Followers"
                    )
                }
            }
            .padding(.vertical, 0)
            .padding(.horizontal, 15)
        }
        .padding(.bottom, 24)
    }

    // MARK: - Follow Button Section
    private var followButtonSection: some View {
        HStack {
            if let targetUserId = userId {
                if isFollowingTarget {
                    Button {
                        Task {
                            await userStore.unfollowUser(userId: targetUserId, autoRefresh: true)
                            // Update local state
                            isFollowingTarget = false
                            // Refresh les followers pour synchroniser
                            viewModel.getFollowers(userId: targetUserId)
                            // Refresh le profil affiché
                            viewModel.fetchUserProfile(userId: targetUserId)
                        }
                    } label: {
                        Text("Unfollow")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(8)
                    }
                } else {
                    Button {
                        Task {
                            await userStore.followUser(userId: targetUserId)
                            // Update local state
                            isFollowingTarget = true
                            // Refresh les followers pour synchroniser
                            viewModel.getFollowers(userId: targetUserId)
                            // Refresh le profil affiché
                            viewModel.fetchUserProfile(userId: targetUserId)
                        }
                    } label: {
                        Text("Follow")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
}

// MARK: - Stat View
struct StatView: View {
    let number: String
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(number)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.footnote)
                .fontWeight(.regular)
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Tab Button
struct TabButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isSelected ? .white : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .background(Color.black)
    }
}

// MARK: - Format Number
private func formatNumber(_ number: Int) -> String {
    switch number {
    case 0..<1_000:
        return "\(number)"
    case 1_000..<1_000_000:
        let thousands = Double(number) / 1_000.0
        return String(format: "%.1fK", thousands).replacingOccurrences(of: ".0", with: "")
    case 1_000_000...:
        let millions = Double(number) / 1_000_000.0
        return String(format: "%.1fM", millions).replacingOccurrences(of: ".0", with: "")
    default:
        return "\(number)"
    }
}

