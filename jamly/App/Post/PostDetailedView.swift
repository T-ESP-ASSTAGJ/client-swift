//
//  PostDetailView.swift
//  jamly
//
//  Created by REVERSS on 29/12/2025.
//

import SwiftUI

struct PostDetailView: View {
    let post: Post
    
    @EnvironmentObject var musicManager: MusicManager
    @EnvironmentObject private var userStore: UserStore
    
    @StateObject private var commentViewModel = CommentViewModel()
    
    @State private var coverUIImage: UIImage?
    @State private var newCommentText: String = ""
    @State private var isLoading: Bool = false
    @State private var isPlaying = true
    
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // MARK - Post Card
                    PostCard(post: post, isCurrentPost: true, showPostDetail: .constant(true), musicManager: musicManager)
                    
                    // MARK: - Track Card
                    trackCard
                        .padding(.top, 20)
                    
                    // MARK: - Caption
                    if !post.caption.isEmpty {
                        captionSection
                            .padding(.top, 20)
                    }
                    
                    // MARK: - Comments Section
                    commentsSection
                        .padding(.top, 24)
                }
                .safeAreaInset(edge: .bottom) {
                    commentInputSection
                }
                .padding(.bottom, 100) // Space for input
            }
            .task {
                await loadData()
            }
            .onTapGesture {
                isTextFieldFocused = false
            }
        }
    }
    
    // MARK: - Track Card
    
    private var trackCard: some View {
        HStack(spacing: 14) {
            // Cover art
            if let coverImg = coverUIImage {
                Image(uiImage: coverImg)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 56, height: 56)
                    .overlay {
                        ProgressView()
                            .tint(.white)
                    }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(post.track.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(post.track.artist.name)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Play button
            Button {
                 Task { await togglePlayPause() }
            } label: {
                Image(systemName: musicManager.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.15))
                    .clipShape(Circle())
            }
            
            // Apple Music button
            Button {
                // Open in Apple Music
            } label: {
                Image(systemName: "apple.logo")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                }
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Caption Section
    
    private var captionSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(post.caption)
                .font(.body)
                .foregroundColor(.white)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Comments Section
    
    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Text("Comments")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("(\(commentViewModel.comments.count))")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            Divider()
                .background(.white.opacity(0.1))
            
            // Comments list
            if commentViewModel.comments.isEmpty && !isLoading {
                emptyCommentsView
            } else if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                    Spacer()
                }
                .padding(.top, 30)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(commentViewModel.comments) { comment in
                        CommentRow(comment: comment)
                            .padding(.horizontal, 20)
                    }
                }
            }
        }
    }
    
    // MARK: - Empty Comments View
    
    private var emptyCommentsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.3))
            
            Text("No comments yet")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white.opacity(0.6))
            
            Text("Be the first to comment!")
                .font(.caption)
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
        .padding(.bottom, 20)
    }
    
    // MARK: - Comment Input Section
    
    private var commentInputSection: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // User avatar
//            if let user = userStore.user {
//                AsyncImage(url: URL(string: user.profilePicture)) { image in
//                    image
//                        .resizable()
//                        .scaledToFill()
//                        .frame(width: 32, height: 32)
//                        .clipShape(Circle())
//                } placeholder: {
//                    Circle()
//                        .fill(Color.gray.opacity(0.3))
//                        .frame(width: 32, height: 32)
//                }
//            }
            
            TextField("Add a comment...", text: $newCommentText, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(.white.opacity(0.1), lineWidth: 1)
                        }
                )
                .foregroundColor(.white)
                .focused($isTextFieldFocused)
                .lineLimit(1...5)
            
            Button {
                Task {
                    await sendComment()
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? .white.opacity(0.3)
                        : .white
                    )
            }
            .disabled(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Methods
    
    private func loadData() async {
        // Load cover image
        if let url = URL(string: post.track.coverUrl) {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let uiImage = UIImage(data: data) {
                    coverUIImage = uiImage
                }
            } catch {
                print("Error loading cover:", error)
            }
        }
        
        // Load comments
        print("ID DU POST")
        print(post.id)
        print("ID DU POST")
        await commentViewModel.getComments(post: post)
    }
    
    private func sendComment() async {
        guard userStore.user != nil else { return }
        
        let trimmedText = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            print("📤 Sending comment: '\(trimmedText)'")
            let response = try await CommentAction.CreateComment(postId: post.id, content: trimmedText)

            print("✅ Comment sent successfully: \(response)")

            withAnimation {
                commentViewModel.comments.insert(response.value, at: 0)
            }

            // Reset text field
            newCommentText = ""
            isTextFieldFocused = false

        } catch {
            print("❌ Failed to send comment: \(error)")
            // TODO: Afficher une alerte d'erreur à l'utilisateur
        }
    }
    
    private func togglePlayPause() async {
        if isPlaying {
            musicManager.pause()
            isPlaying = false
        } else {
            await musicManager.play()
            isPlaying = true
        }
    }
}

