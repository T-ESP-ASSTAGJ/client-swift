import SwiftUI
import MusicKit

struct HomeFeed: View {
    @EnvironmentObject private var userStore: UserStore
    @EnvironmentObject private var musicManager: MusicManager
    
    @Binding var scrollPosition: Int?  // ✅ Change en @Binding
    @Binding var selectedSegment: FeedSegment
    
    @State private var showPostDetail: Bool = false
    @State private var pendingMusicChange: Task<Void, Never>?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                ScrollView {
                    if userStore.isLoadingFeed {
                        ProgressView()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    } else if userStore.feed.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "music.note.list")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("No post found for now. Try creating a new one! ")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(userStore.feed, id: \.id) { post in
                                PostCard(
                                    post: post,
                                    isCurrentPost: post.id == scrollPosition,
                                    showPostDetail: $showPostDetail,   // ✅ showPostDetail avant musicManager
                                    musicManager: musicManager
                                )
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .id(post.id)
                                .onTapGesture {
                                    if post.id == scrollPosition {
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
                            }
                        }
                        .scrollTargetLayout()
                    }
                }
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: $scrollPosition)  // ✅ Utilise le binding
                .onChange(of: scrollPosition) { oldValue, newValue in
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
                .refreshable {
                    await userStore.loadFeed(forceRefresh: true)
                }
            }
        }
        .onAppear {
            // ✅ Simplifié : juste initialise si nil
            if scrollPosition == nil, let firstPost = userStore.feed.first {
                scrollPosition = firstPost.id
            }
            
            // Reprend la musique
            if let currentId = scrollPosition,
               let post = userStore.feed.first(where: { $0.id == currentId }) {
                Task {
                    await playPostMusic(post)
                }
            }
        }
        .onChange(of: selectedSegment) { oldValue, newValue in
            musicManager.pause()
            pendingMusicChange?.cancel()
            Task {
                await loadFeedBasedOnSegment()
            }
        }
        .onDisappear {
            if !showPostDetail {
                musicManager.pause()
            }
            pendingMusicChange?.cancel()
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
}
