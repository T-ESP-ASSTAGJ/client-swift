//
//  JamPostCard.swift
//  jamly
//
//  Created by REVERSS on 05/12/2025.
//

import SwiftUI

struct PostCard: View {
    let post: Post
    let isCurrentPost: Bool
    
    @Binding var showPostDetail: Bool
    
    @ObservedObject var musicManager: MusicManager
    
    @StateObject private var viewModel = PostViewModel()
    
    @State private var coverUIImage: UIImage?
    @State private var avatarUIImage: UIImage?
    @State private var isSwapped = false
    
    // ✅ États locaux pour le like
    @State private var isLiked: Bool
    @State private var likesCount: Int
    
    // Seuil pour afficher "See more" (environ 2 lignes)
    private let captionTruncationThreshold = 80

    private var shouldShowSeeMore: Bool {
        post.caption.count > captionTruncationThreshold
    }
    
    init(post: Post, isCurrentPost: Bool, showPostDetail: Binding<Bool>, musicManager: MusicManager) {
        self.post = post
        self.isCurrentPost = isCurrentPost

        // Initialize property wrappers
        self._showPostDetail = showPostDetail
        self._musicManager = ObservedObject(initialValue: musicManager)

//        print("Current post: \(post)")
        
        // ✅ Initialiser avec les valeurs du post
        self._isLiked = State(initialValue: post.isLiked)
        self._likesCount = State(initialValue: post.likesCount)
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header utilisateur
                HStack {
                    AsyncImage(url: URL(string: post.user.profilePicture)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 40, height: 40)
                            .overlay {
                                ProgressView()
                            }
                    }
                    
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
                    
                    Spacer()
                    
                    Text("23 minutes ago")
                        .font(.caption)
                        .foregroundColor(.white)
                        .opacity(0.7)
                }
                .padding(.top, 25)
                .padding(.horizontal, 15)
                .padding(.bottom, 15)
                
                // Image principale avec boutons
                ZStack(alignment: .bottom) {
                    // 🎨 IMAGE PRINCIPALE + MINIATURE
                    ZStack(alignment: .topTrailing) {
                        // IMAGE PRINCIPALE AVEC BOUTON PAUSE CENTRÉ
                        ZStack {
                            Group {
                                if let img = isSwapped ? avatarUIImage : coverUIImage {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    Color.gray.opacity(0.2)
                                }
                            }
                            
                            // ✅ BOUTON PAUSE CENTRÉ
                            if !musicManager.isPlaying && isCurrentPost {
                                ZStack {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 36, weight: .semibold))
                                        .contentTransition(.symbolEffect(.replace))
                                        .foregroundStyle(.white.opacity(0.6))
                                        .shadow(color: .white.opacity(0.6), radius: 4, x: 0, y: 0)
                                        .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 4)
                                }
                                .opacity(musicManager.isPlaying ? 0 : 0.8)
                                .animation(.easeInOut(duration: 0.2), value: musicManager.isPlaying)
                            }
                        }
                        .frame(width: 370, height: 400)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        
                        HStack(alignment: .top) {
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
                            
                            Spacer()
                            
                            // 👉 BOUTON MINIATURE DROITE
                            ZStack {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isSwapped.toggle()
                                    }
                                } label: {
                                    ZStack {
                                        if let img = isSwapped ? coverUIImage : avatarUIImage {
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
                            }
                            .padding(.top, 20)
                            .padding(.horizontal, 16)
                        }
                        .frame(width: 370)
                    }
                    .task {
                        await preloadImages()
                    }
                    
                    // ❤️ STATISTIQUES (en bas)
                    if !showPostDetail {
                        HStack(spacing: 10) {
                            VStack {
                                Button(action: {
                                    toggleLike()
                                }) {
                                    VStack(spacing: 5) {
                                        Image(systemName: isLiked ? "heart.fill" : "heart")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(isLiked ? .red : .white)
                                            .symbolEffect(.bounce, value: isLiked)
                                    }
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 7)
                                }
                                .buttonStyle(.glass)
                                .buttonBorderShape(.circle)
                                
                                Text("\(likesCount)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .opacity(0.8)
                            }
                            
                            VStack {
                                Button(action: {
                                    showPostDetail = true
                                }) {
                                    VStack(spacing: 5) {
                                        Image(systemName: "text.bubble")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    .padding(.horizontal, 6.5)
                                    .padding(.vertical, 6.5)
                                }
                                .buttonStyle(.glass)
                                .buttonBorderShape(.circle)
                                
                                Text(String(post.commentsCount))
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .opacity(0.8)
                            }
                        }
                        .offset(y: -20)
                    }
                    }
                
                // 📝 FOOTER: Track Info + Caption
                if !showPostDetail{
                    VStack(alignment: .leading, spacing: 12) {
                        // Track info (toujours affiché)
                        HStack(alignment: .center) {
                            HStack(spacing: 8) {
                                // Mini cover art
                                if let coverImg = coverUIImage {
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
                                    
                                    Text(post.track.artist.name)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                        .lineLimit(1)
                                }
                            }
                            
                            Spacer()
                            
                            // Bouton Apple Music
                            Button {
                                // Action pour ouvrir dans Apple Music
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
                        
                        // Caption (si présent)
                        if !post.caption.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(post.caption)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                                
                                // "See more" ouvre PostDetailView
                                if shouldShowSeeMore {
                                    Button {
                                        showPostDetail = true
                                    } label: {
                                        Text("See more")
                                            .font(.subheadline.weight(.medium))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 15)
                }
            }
        }
        .navigationDestination(isPresented: $showPostDetail) {
            PostDetailView(post: post)
        }
    }
    
    // ✅ Fonction toggle propre
    private func toggleLike() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            if isLiked {
                // Unlike
                isLiked = false
                likesCount -= 1
                viewModel.unlikePost(post: post)
            } else {
                // Like
                isLiked = true
                likesCount += 1
                viewModel.likePost(post: post)
            }
        }
    }
    
    private var truncatedCaption: String {
        if post.caption.count > captionTruncationThreshold {
            return String(post.caption.prefix(captionTruncationThreshold)) + "..."
        }
        return post.caption
    }
    
    func preloadImages() async {
        if coverUIImage != nil && avatarUIImage != nil { return }
        
        async let coverData = fetchImageData(from: post.track.coverUrl)
        async let avatarData = fetchImageData(from: post.photoUrl)
        
        if let data = await coverData, let uiImage = UIImage(data: data) {
            coverUIImage = uiImage
        }
        if let data = await avatarData, let uiImage = UIImage(data: data) {
            avatarUIImage = uiImage
        }
    }
    
    func fetchImageData(from urlString: String) async -> Data? {
        guard let url = URL(string: urlString) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        } catch {
            print("Erreur chargement image:", error)
            return nil
        }
    }
}

