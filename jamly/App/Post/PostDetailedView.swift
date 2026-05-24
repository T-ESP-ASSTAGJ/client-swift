//
//  PostDetailView.swift
//  jamly
//
//  Created by REVERSS on 29/12/2025.
//

import SwiftUI

struct PostDetailView: View {
    let post: Post
    let highlightedCommentId: Int?

    @EnvironmentObject var musicManager: MusicManager
    @EnvironmentObject private var userStore: UserStore

    @StateObject private var commentViewModel = CommentViewModel()

    @State private var newCommentText: String = ""
    @State private var isSending: Bool = false
    @State private var navigateToProfile: Int? = nil

    @State private var didScrollToHighlighted = false

    @State private var commentToDelete: CommentResponse?
    @State private var showDeleteConfirmation: Bool = false

    @FocusState private var isTextFieldFocused: Bool

    init(post: Post, highlightedCommentId: Int? = nil) {
        self.post = post
        self.highlightedCommentId = highlightedCommentId
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                PostCard(
                    post: post,
                    isCurrentPost: true,
                    currentUserId: userStore.user?.id,
                    onSeeMore: {
                        // No-op : on est déjà dans la vue détail, pas de navigation à effectuer.
                    },
                    onOpenComments: {
                        // No-op : les commentaires sont affichés inline plus bas, pas dans une sheet.
                    },
                    onDeleted: { navigateToProfile = post.user.id },
                    showPostDetail: .constant(true),
                    musicManager: musicManager
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                trackCard
                    .listRowInsets(EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                if !post.caption.isEmpty {
                    captionSection
                        .listRowInsets(EdgeInsets(top: 18, leading: 0, bottom: 0, trailing: 0))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                commentsHeader
                    .listRowInsets(EdgeInsets(top: 28, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                commentsListContent
            }
            .scrollContentBackground(.hidden)
            .listStyle(.plain)
            .background(Color.appBackground.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                commentInputSection
            }
            .task {
                await commentViewModel.getComments(post: post, highlightedCommentId: highlightedCommentId)
            }
            .onChange(of: commentViewModel.comments.count) { _, _ in
                scrollToHighlightedComment(proxy: proxy)
            }
            .onTapGesture {
                isTextFieldFocused = false
            }
            .alert("Delete this comment?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    commentToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let comment = commentToDelete {
                        Task {
                            await commentViewModel.deleteComment(commentId: comment.id)
                        }
                    }
                    commentToDelete = nil
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
        .navigationDestination(item: $navigateToProfile) { userId in
            ProfileView(userId: userId)
        }
    }

    // MARK: - Comments Header & List

    private var commentsHeader: some View {
        HStack(spacing: 8) {
            Text("Comments")
                .font(.headline)
                .foregroundColor(.white)

            if !commentViewModel.comments.isEmpty {
                Text("\(commentViewModel.comments.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.white.opacity(0.1), in: Capsule())
            }

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var commentsListContent: some View {
        if commentViewModel.comments.isEmpty {
            emptyCommentsView
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        } else {
            ForEach(commentViewModel.comments) { comment in
                CommentRow(
                    comment: comment,
                    isHighlighted: comment.id == highlightedCommentId
                )
                .id(comment.id)
                .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    if isOwnComment(comment) {
                        Button(role: .destructive) {
                            commentToDelete = comment
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    private func scrollToHighlightedComment(proxy: ScrollViewProxy) {
        guard !didScrollToHighlighted,
              let highlightedCommentId,
              commentViewModel.comments.contains(where: { $0.id == highlightedCommentId })
        else { return }
        didScrollToHighlighted = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 200_000_000)
            withAnimation(.easeInOut(duration: 0.4)) {
                proxy.scrollTo(highlightedCommentId, anchor: .center)
            }
        }
    }

    // MARK: - Track Card

    private var trackCard: some View {
        HStack(spacing: 14) {
            ProfilePostThumbnail(imageURL: post.track.coverImage)
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(post.track.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Image(systemName: "music.note")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                    Text(post.track.artistName)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
            }

            Spacer()

            Button {
                Task { await togglePlayPause() }
            } label: {
                Image(systemName: isCurrentTrackPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.6, green: 0.4, blue: 0.9),
                                Color(red: 0.8, green: 0.4, blue: 0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                }
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Caption Section

    private var captionSection: some View {
        (
            Text("@\(post.user.username) ")
                .font(.body.weight(.semibold))
                .foregroundColor(.white)
            + Text(post.caption)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
        )
        .lineSpacing(4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
    }

    // MARK: - Empty Comments View

    private var emptyCommentsView: some View {
        VStack(spacing: 10) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(.white.opacity(0.25))

            Text("No comments yet")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white.opacity(0.55))

            Text("Be the first to comment")
                .font(.caption)
                .foregroundColor(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 36)
        .padding(.bottom, 20)
    }

    // MARK: - Comment Input Section

    private var commentInputSection: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Add a comment…", text: $newCommentText, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(
                    Capsule()
                        .fill(.white.opacity(0.08))
                        .overlay {
                            Capsule()
                                .stroke(
                                    isTextFieldFocused
                                        ? .white.opacity(0.2)
                                        : .white.opacity(0.08),
                                    lineWidth: 1
                                )
                        }
                )
                .foregroundColor(.white)
                .focused($isTextFieldFocused)
                .lineLimit(1...5)

            Button {
                Task { await sendComment() }
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(
                        Group {
                            if isSendDisabled {
                                Color.white.opacity(0.12)
                            } else {
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.6, green: 0.4, blue: 0.9),
                                        Color(red: 0.8, green: 0.4, blue: 0.7)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            }
                        }
                    )
                    .clipShape(Circle())
            }
            .disabled(isSendDisabled)
            .animation(.easeInOut(duration: 0.15), value: isSendDisabled)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(.white.opacity(0.06))
                .frame(height: 1)
        }
    }

    private var isSendDisabled: Bool {
        newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending
    }

    // MARK: - Methods

    private func isOwnComment(_ comment: CommentResponse) -> Bool {
        userStore.user?.id == comment.user.id
    }

    private func sendComment() async {
        guard userStore.user != nil else { return }

        let trimmedText = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        isSending = true
        defer { isSending = false }

        do {
            _ = try await commentViewModel.sendComment(postId: post.id, content: trimmedText)
            newCommentText = ""
            isTextFieldFocused = false
        } catch {
            print("❌ Failed to send comment: \(error)")
        }
    }

    private var isCurrentTrackPlaying: Bool {
        musicManager.isPlaying && musicManager.currentSongId == post.track.songId
    }

    private func togglePlayPause() async {
        if isCurrentTrackPlaying {
            musicManager.pause()
        } else {
            await musicManager.playPreview(songId: post.track.songId)
        }
    }
}
