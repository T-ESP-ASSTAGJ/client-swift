import SwiftUI
import MusicKit

struct HomeFeed: View {
    @EnvironmentObject private var userStore: UserStore
    @EnvironmentObject private var musicManager: MusicManager
    
    @Binding var selectedSegment: FeedSegment
    @Binding var discoveryScrollPosition: Int?
    @Binding var friendsScrollPosition: Int?
    
    @State private var showPostDetail: Bool = false
    @State private var pendingMusicChange: Task<Void, Never>?
    
    var body: some View {
        GeometryReader { geometry in
            feedScrollView(geometry: geometry)
                .onAppear {
                    handleOnAppear()
                }
                .onChange(of: selectedSegment) { oldValue, newValue in
                    handleSegmentChange()
                }
                .onDisappear {
                    handleOnDisappear()
                }
        }
    }
    
    // MARK: - Sub-views
    
    @ViewBuilder
    private func feedScrollView(geometry: GeometryProxy) -> some View {
        ZStack(alignment: .top) {
            ScrollView {
                feedContentView(geometry: geometry)
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: currentScrollPositionBinding)
            .onChange(of: currentScrollPosition) { oldValue, newValue in
                handleScrollPositionChange(newValue)
            }
            .refreshable {
                await loadFeedBasedOnSegment()
            }
        }
    }
    
    @ViewBuilder
    private func feedContentView(geometry: GeometryProxy) -> some View {
        if userStore.isLoadingFeed {
            loadingView(geometry: geometry)
        } else if userStore.feed.isEmpty {
            emptyStateView(geometry: geometry)
        } else {
            postListView(geometry: geometry)
        }
    }
    
    private func loadingView(geometry: GeometryProxy) -> some View {
        ProgressView()
            .frame(width: geometry.size.width, height: geometry.size.height)
    }
    
    private func emptyStateView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            Text("No post found for now. Try creating a new one! ")
                .font(.headline)
                .foregroundColor(.gray)
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
    }
    
    private func postListView(geometry: GeometryProxy) -> some View {
        LazyVStack(spacing: 0) {
            ForEach(userStore.feed, id: \.id) { post in
                postCardView(post: post, geometry: geometry)
            }
            
            if userStore.isLoadingMoreFeed {
                loadingMoreView(geometry: geometry)
            }
        }
        .scrollTargetLayout()
    }
    
    private func postCardView(post: Post, geometry: GeometryProxy) -> some View {
        PostCard(
            post: post,
            isCurrentPost: post.id == currentScrollPosition,
            showPostDetail: $showPostDetail,
            musicManager: musicManager
        )
        .frame(width: geometry.size.width, height: geometry.size.height)
        .id(post.id)
        .onAppear {
            handlePostAppear(post)
        }
        .onTapGesture {
            handlePostTap(post)
        }
    }
    
    private func loadingMoreView(geometry: GeometryProxy) -> some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Spacer()
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
    }
    
    // MARK: - Event Handlers
    
    private func handleOnAppear() {
        Task {
            if userStore.feed.isEmpty {
                await userStore.loadBothFeeds()
            }
            
            // Initialize scroll position if needed
            if currentScrollPosition == nil, let firstPost = userStore.feed.first {
                if selectedSegment == FeedSegment.friends {
                    friendsScrollPosition = firstPost.id
                } else {
                    discoveryScrollPosition = firstPost.id
                }
            }
            
            // Resume music
            if let currentId = currentScrollPosition,
               let post = userStore.feed.first(where: { $0.id == currentId }) {
                await playPostMusic(post)
            }
        }
    }
    
    private func handleSegmentChange() {
        musicManager.pause()
        pendingMusicChange?.cancel()
        
        let mode = selectedSegment == .friends ? "private" : "public"
        Task {
            await userStore.loadFeed(page: 1, forceRefresh: false, mode: mode)
            
            // Always return to first post when changing segment
            if let firstPost = userStore.feed.first {
                if selectedSegment == .friends {
                    friendsScrollPosition = firstPost.id
                } else {
                    discoveryScrollPosition = firstPost.id
                }
                
                // Play music for first post
                await playPostMusic(firstPost)
            }
        }
    }
    
    private func handleOnDisappear() {
        if !showPostDetail {
            musicManager.pause()
        }
        pendingMusicChange?.cancel()
    }
    
    private func handleScrollPositionChange(_ newValue: Int?) {
        pendingMusicChange?.cancel()
        
        pendingMusicChange = Task {
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }
            
            if let postId = newValue,
               let post = userStore.feed.first(where: { $0.id == postId }) {
                await playPostMusic(post)
            }
        }
    }
    
    private func handlePostAppear(_ post: Post) {
        if post.id == userStore.feed.last?.id {
            print("Dernier post atteint, chargement de la nouvelle page")
            Task {
                await userStore.loadMoreFeed()
            }
        }
    }
    
    private func handlePostTap(_ post: Post) {
        if post.id == currentScrollPosition {
            withAnimation {
                if musicManager.isPlaying {
                    musicManager.pause()
                } else {
                    Task {
                        await musicManager.play()
                    }
                }
            }
        }
    }
    
    // ✅ Fonction helper pour charger le bon feed
    private func loadFeedBasedOnSegment() async {
        let mode = selectedSegment == .friends ? "private" : "public"
        await userStore.loadFeed(page: 1, forceRefresh: true, mode: mode)
    }
    
    private func playPostMusic(_ post: Post) async {
        guard let trackId = getTestTrackId(for: post) else {
            musicManager.pause()
            return
        }
        
        await musicManager.playTrackById(trackId)
    }
    
    private func getTestTrackId(for post: Post) -> String? {
        let testTrackIds = [
            "1440873687",
            "1554171602",
            "1851616662",
            "1853899855"
        ]
        
        if let index = userStore.feed.firstIndex(where: { $0.id == post.id }) {
            return testTrackIds[index % testTrackIds.count]
        }
        
        return testTrackIds.first
    }
    
    private var currentScrollPositionBinding: Binding<Int?> {
        if selectedSegment == FeedSegment.discovery {
            return $discoveryScrollPosition
        } else {
            return $friendsScrollPosition
        }
    }
    
    private var currentScrollPosition: Int? {
        if selectedSegment == .discovery {
            return discoveryScrollPosition
        } else {
            return friendsScrollPosition
        }
    }
}
