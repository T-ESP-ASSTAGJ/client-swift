//
//  PostCard.swift
//  jamly
//
//  Created by REVERSS on 05/12/2025.
//

import SwiftUI
import Combine

struct PostCard: View {
    let post: Post
    let isCurrentPost: Bool
    let currentUserId: Int?
    let onSeeMore: () -> Void
    let onOpenComments: () -> Void
    let onDeleted: (() -> Void)?
    /// Toggle play/pause déclenché par un tap sur l'image uniquement (pas toute la carte),
    /// pour ne pas voler les taps des contrôles (user, menu, see more).
    let onTogglePlayback: (() -> Void)?

    @Binding var showPostDetail: Bool

    @ObservedObject var musicManager: MusicManager

    @StateObject private var viewModel = PostViewModel()

    @State private var selectedUserId: Int?
    @State private var frontImage: UIImage?
    @State private var backImage: UIImage?
    @State private var coverImage: UIImage?
    @State private var isSwapped = false

    @State private var isLiked: Bool
    @State private var likesCount: Int
    @State private var commentsCount: Int
    @State private var showReportSheet = false
    @State private var isReported = false
    @State private var showAlreadyReportedToast = false
    @State private var showDeleteConfirmation = false

    @State private var currentTime = Date()

    private let captionTruncationThreshold = 80
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    init(post: Post, isCurrentPost: Bool, currentUserId: Int?, onSeeMore: @escaping () -> Void, onOpenComments: @escaping () -> Void, onDeleted: (() -> Void)? = nil, onTogglePlayback: (() -> Void)? = nil, showPostDetail: Binding<Bool>, musicManager: MusicManager) {
        self.post = post
        self.isCurrentPost = isCurrentPost
        self.currentUserId = currentUserId
        self.onSeeMore = onSeeMore
        self.onOpenComments = onOpenComments
        self.onDeleted = onDeleted
        self.onTogglePlayback = onTogglePlayback

        self._showPostDetail = showPostDetail
        self._musicManager = ObservedObject(initialValue: musicManager)

        self._isLiked = State(initialValue: post.isLiked)
        self._likesCount = State(initialValue: post.likesCount)
        self._commentsCount = State(initialValue: post.commentsCount)
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                userHeader

                ZStack(alignment: .bottom) {
                    mainImageSection

                    if !showPostDetail {
                        statsButtons
                    }
                }

                if !showPostDetail {
                    footerSection
                }

                Spacer()
            }
        }
        .padding(.top, !showPostDetail ? 20 : 0)
        .overlay(alignment: .top) {
            if showAlreadyReportedToast {
                HStack(spacing: 8) {
                    Image(systemName: "flag.fill")
                        .foregroundColor(.white)
                    Text("Already reported")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.9))
                )
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        withAnimation(.easeOut(duration: 0.3)) {
                            showAlreadyReportedToast = false
                        }
                    }
                }
            }
        }
        .navigationDestination(item: $selectedUserId) { userId in
            ProfileView(userId: userId)
        }
        .sheet(isPresented: $showReportSheet) {
            ReportPostSheetView(post: post, isReported: $isReported)
        }
        .alert("Delete this post?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                viewModel.deletePost(postId: post.id) {
                    onDeleted?()
                }
            }
            Button("Cancel", role: .cancel) {
                // No action needed — SwiftUI dismisses the alert automatically for .cancel buttons
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .onAppear {
            viewModel.viewPost(post: post)
        }
    }

    // MARK: - User Header

    private var userHeader: some View {
        HStack {
            CachedAsyncImage(
                url: URL(string: post.user.profilePicture),
                targetSize: CGSize(width: 40, height: 40)
            ) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    }
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(post.user.username)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                if !post.location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                        Text(post.location)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.secondary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                selectedUserId = post.user.id
            }

            Spacer()

            Text(formatRelativeTime(post.createdAt))
                .font(.caption)
                .foregroundColor(.white)
                .opacity(0.7)
                .onReceive(timer) { _ in
                    currentTime = Date()
                 }
            Menu {
                if post.user.id == currentUserId {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } else {
                    // Report n'est pas une action destructive pour l'utilisateur courant :
                    // texte par défaut (blanc), contrairement à Delete qui reste rouge.
                    Button {
                        if isReported {
                            showAlreadyReportedToast = true
                        } else {
                            showReportSheet = true
                        }
                    } label: {
                        Label(isReported ? "Already reported" : "Report", systemImage: isReported ? "flag.fill" : "flag")
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(8)
            }
        }
        .padding(.top, 25)
        .padding(.horizontal, 15)
        .padding(.bottom, 15)
    }

    // MARK: - Main Image Section

    private var mainImageSection: some View {
        ZStack(alignment: .topTrailing) {
            ZStack {
                Group {
                    if let img = isSwapped ? backImage : frontImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Color.gray.opacity(0.2)
                    }
                }

                if !musicManager.isPlaying && isCurrentPost {
                    Image(systemName: "play.fill")
                        .font(.system(size: 36, weight: .semibold))
                        .contentTransition(.symbolEffect(.replace))
                        .foregroundStyle(.white.opacity(0.6))
                        .shadow(color: .white.opacity(0.6), radius: 4, x: 0, y: 0)
                        .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 4)
                        .opacity(0.8)
                        .animation(.easeInOut(duration: 0.2), value: musicManager.isPlaying)
                }
            }
            .frame(width: 370, height: 400)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .contentShape(RoundedRectangle(cornerRadius: 24))
            .onTapGesture { onTogglePlayback?() }

            HStack(alignment: .top) {
                playingBadge
                Spacer()
                thumbnailButton
            }
            .frame(width: 370)
        }
        .task {
            await preloadImages()
        }
    }

    private var playingBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "music.note")
                .font(.system(size: 11, weight: .semibold))

            Text("Playing")
                .font(.caption.weight(.medium))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.3), lineWidth: 1)
        }
        .padding(.top, 20)
        .padding(.horizontal, 16)
        .opacity(isCurrentPost && musicManager.isPlaying ? 1 : 0)
        .animation(.easeInOut(duration: 0.2), value: musicManager.isPlaying)
    }

    private var thumbnailButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isSwapped.toggle()
            }
        } label: {
            ZStack {
                if let img = isSwapped ? frontImage : backImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.gray.opacity(0.2)
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(.top, 20)
        .padding(.horizontal, 16)
    }

    // MARK: - Stats Buttons

    private var statsButtons: some View {
        HStack(spacing: 20) {
            VStack {
                Button(action: toggleLike) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isLiked ? .red : .white)
                        .symbolEffect(.bounce, value: isLiked)
                        .padding(6.5)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .sensoryFeedback(.impact(weight: .medium), trigger: isLiked)

                Text(String(likesCount))
                    .font(.headline)
                    .foregroundColor(.white)
                    .opacity(0.8)
            }

            VStack {
                Button(action: onOpenComments) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(6.5)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)

                Text(String(commentsCount))
                    .font(.headline)
                    .foregroundColor(.white)
                    .opacity(0.8)
            }
        }
        .offset(y: -20)
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            trackInfo

            if !post.caption.isEmpty {
                captionSection
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 15)
    }

    private var trackInfo: some View {
        HStack(alignment: .center) {
            HStack(spacing: 8) {
                if let coverImg = coverImage {
                    Image(uiImage: coverImg)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 36, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 36, height: 36)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.track.title)
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(post.track.artistName)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
            }

            Spacer()

            Button {
                let urlString: String
                if !post.track.songId.isEmpty {
                    urlString = "https://music.apple.com/song/\(post.track.songId)"
                } else {
                    urlString = "https://music.apple.com/search?term=\(post.track.title) \(post.track.artistName)"
                        .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                }
                if let url = URL(string: urlString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Image(systemName: "apple.logo")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                }
        )
    }

    private var captionSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(post.caption)
                .font(.subheadline)
                .foregroundColor(.white)
                .lineLimit(2)

            Button(action: onSeeMore) {
                Text("See more")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }

    // MARK: - Actions
    
    private func toggleLike() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            if isLiked {
                isLiked = false
                likesCount -= 1
                viewModel.unlikePost(post: post)
            } else {
                isLiked = true
                likesCount += 1
                viewModel.likePost(post: post)
            }
        }
    }
    
    // MARK: - Image Loading
    
    func preloadImages() async {
        if frontImage != nil && backImage != nil && coverImage != nil { return }
        
        async let frontData = fetchImageData(from: post.frontImage)
        async let backData = fetchImageData(from: post.backImage)
        async let coverData = fetchImageData(from: post.track.coverImage)
        
        if let data = await frontData, let uiImage = UIImage(data: data) {
            await MainActor.run { self.frontImage = uiImage }
        }
        if let data = await backData, let uiImage = UIImage(data: data) {
            await MainActor.run { self.backImage = uiImage }
        }
        if let data = await coverData, let uiImage = UIImage(data: data) {
            await MainActor.run { self.coverImage = uiImage }
        }
    }
    
    func fetchImageData(from urlString: String) async -> Data? {
        let fullURL = buildFullImageURL(urlString)
        guard let url = URL(string: fullURL) else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                return data
            }
            return nil
        } catch {
            return nil
        }
    }

    private func buildFullImageURL(_ urlString: String) -> String {
        if urlString.starts(with: "http://") || urlString.starts(with: "https://") {
            return urlString
        }
        let baseURL = Config.baseURL
        return baseURL + urlString
    }
}
