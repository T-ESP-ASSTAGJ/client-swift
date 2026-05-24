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
                        .navigationDestination(for: Conversation.self) { conversation in
                            ChatDetailView(conversation: conversation)
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
        .overlay {
            if authManager.shouldShowTutorial {
                TutorialOverlayView(selectedTab: $selectedTab) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        authManager.dismissTutorial()
                    }
                }
                .transition(.opacity)
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
        .onReceive(NotificationManager.shared.$pendingConversationId) { conversationId in
            guard let conversationId else { return }
            print("🚀 Navigation vers conversation \(conversationId)")
            NotificationManager.shared.pendingConversationId = nil
            Task {
                await loadAndNavigateToConversation(id: conversationId)
            }
        }
    }

    // MARK: - Load Conversation

    private func loadAndNavigateToConversation(id: Int) async {
        do {
            let response = try await ConversationAction.getConversationDetail(conversationId: id)
            let detail = response.value
            let conversation = Conversation(
                config: ConversationConfig(
                    id: detail.id,
                    isGroup: detail.isGroup,
                    groupName: detail.groupName ?? "",
                    memberCount: detail.memberCount
                ),
                type: detail.isGroup ? "group" : "direct",
                lastMessage: nil,
                participants: detail.participants
            )
            chatsTabPath = NavigationPath()
            chatsTabPath.append(conversation)
            selectedTab = .chats
            print("✅ Conversation \(id) chargée et navigation effectuée")
        } catch {
            print("❌ Erreur lors du chargement de la conversation \(id): \(error)")
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

// MARK: - Tutorial Overlay

private struct TutorialStep {
    let tab: TabItem
    let icon: String
    let title: String
    let description: String
    let accent: [Color]
}

struct TutorialOverlayView: View {
    @Binding var selectedTab: TabItem
    let onFinish: () -> Void

    @State private var stepIndex: Int = 0

    private let steps: [TutorialStep] = [
        TutorialStep(
            tab: .home,
            icon: "rectangle.stack.badge.play.fill",
            title: "Ton feed",
            description: "Retrouve ici les morceaux partagés par tes amis et le contenu sélectionné pour toi.",
            accent: [.purple, .pink]
        ),
        TutorialStep(
            tab: .discover,
            icon: "safari",
            title: "Discover",
            description: "Explore la mosaïque des posts publics, trouve de nouveaux artistes et des coups de cœur.",
            accent: [.blue, .cyan]
        ),
        TutorialStep(
            tab: .create,
            icon: "plus.circle.fill",
            title: "Publie un post",
            description: "Partage le morceau du moment en quelques secondes avec une photo avant/arrière.",
            accent: [.orange, .pink]
        ),
        TutorialStep(
            tab: .chats,
            icon: "ellipsis.message.fill",
            title: "Discute",
            description: "Échange en privé ou en groupe avec tes amis sur leurs sons partagés.",
            accent: [.green, .mint]
        ),
        TutorialStep(
            tab: .profile,
            icon: "person.crop.circle.fill",
            title: "Ton profil",
            description: "Tes posts, tes stats et tes paramètres se retrouvent ici. Tu peux rejouer ce tutoriel à tout moment.",
            accent: [.purple, .blue]
        ),
    ]

    private var current: TutorialStep { steps[stepIndex] }
    private var isLast: Bool { stepIndex == steps.count - 1 }
    private var tabCount: Int { TabItem.allCases.count }

    private let tabBarHeight: CGFloat = 49

    var body: some View {
        GeometryReader { geo in
            let tabIndex = TabItem.allCases.firstIndex(of: current.tab) ?? 0
            let tabCenterX = geo.size.width * (CGFloat(tabIndex) + 0.5) / CGFloat(tabCount)
            let tabBarTopY = geo.size.height - geo.safeAreaInsets.bottom - tabBarHeight
            let cardBottomReserve = geo.safeAreaInsets.bottom + tabBarHeight + 40

            ZStack {
                Color.black.opacity(0.72)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { /* swallow */ }

                VStack(spacing: 0) {
                    Spacer()
                    card
                        .padding(.horizontal, 20)
                    Spacer()
                        .frame(height: cardBottomReserve)
                }

                // Pointer: positionné en absolu pile au-dessus de la tab active
                Image(systemName: "chevron.down")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 4)
                    .position(x: tabCenterX, y: tabBarTopY - 8)
            }
            .animation(.easeInOut(duration: 0.25), value: stepIndex)
        }
    }

    private var card: some View {
        VStack(spacing: 18) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: current.accent,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    Image(systemName: current.icon)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Étape \(stepIndex + 1) / \(steps.count)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.5))
                    Text(current.title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                }

                Spacer()

                Button(action: skip) {
                    Text("Skip")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .accessibilityIdentifier("tutorial.skipButton")
            }

            Text(current.description)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 6) {
                ForEach(0..<steps.count, id: \.self) { i in
                    Capsule()
                        .fill(i == stepIndex ? Color.white : Color.white.opacity(0.25))
                        .frame(width: i == stepIndex ? 22 : 6, height: 6)
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: stepIndex)
                }
                Spacer()
            }

            HStack(spacing: 10) {
                if stepIndex > 0 {
                    Button(action: previous) {
                        Text("Back")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.white.opacity(0.1), in: Capsule())
                    }
                    .accessibilityIdentifier("tutorial.backButton")
                }

                Button(action: next) {
                    Text(isLast ? "C'est parti" : "Suivant")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white, in: Capsule())
                }
                .accessibilityIdentifier(isLast ? "tutorial.doneButton" : "tutorial.nextButton")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                }
        )
    }

    private func next() {
        if isLast {
            onFinish()
            return
        }
        stepIndex += 1
        withAnimation(.easeInOut(duration: 0.25)) {
            selectedTab = current.tab
        }
    }

    private func previous() {
        guard stepIndex > 0 else { return }
        stepIndex -= 1
        withAnimation(.easeInOut(duration: 0.25)) {
            selectedTab = current.tab
        }
    }

    private func skip() {
        onFinish()
    }
}
