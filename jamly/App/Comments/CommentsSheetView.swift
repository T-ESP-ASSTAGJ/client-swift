//
//  CommentsSheet.swift
//  jamly
//
//  Created by Jonathan Dumesnil on 21/12/2025.
//

import SwiftUI

struct CommentsSheetView: View {
    let post: Post
    
    @EnvironmentObject private var userStore: UserStore
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var commentViewModel = CommentViewModel()
    
    @State private var newCommentText: String = ""
    @State private var isLoading: Bool = false
    
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                commentHeader
                
                Divider()
                    .padding(.top, 20)
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if commentViewModel.comments.isEmpty && !commentViewModel.isLoading {
                            Spacer()
                            emptyStateView
                            Spacer()
                        } else if commentViewModel.isLoading {
                            Spacer()
                            ProgressView()
                                .scaleEffect(1.2)
                                .padding(.top, 60)
                            Spacer()
                        } else {
                            ForEach(commentViewModel.comments) { comment in
                                CommentRow(comment: comment)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            
            }
            .safeAreaInset(edge: .bottom) {
                commentInputSection
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
            }
            .navigationTitle("\(post.commentsCount) comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Label("close", systemImage: "xmark")
                    }
                }
            }
            .task {
                await commentViewModel.getComments(post: post)
            }
        }
    }
    
    // MARK: - Post Header
    
    private var commentHeader: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: post.photoUrl)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(post.track.title)
                    .font(.headline)
                    .textCase(.uppercase)
                Text(post.track.artist.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("Any comments")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("Be the first to comment!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
        .offset(y: 90)
    }
    
    // MARK: - Comment Input Section
    
    private var commentInputSection: some View {
        HStack(alignment: .bottom, spacing: 12) {
            TextField("Write a comment...", text: $newCommentText, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(12)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .focused($isTextFieldFocused)
                .lineLimit(1...5)
            
            Button {
                Task {
                    await sendComment()
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
            }
            .disabled(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    
    private func sendComment() async {
        guard userStore.user != nil else { return }
        
        let trimmedText = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            _ = try await commentViewModel.sendComment(postId: post.id, content: trimmedText)
            
            // Reset text field
            newCommentText = ""
            isTextFieldFocused = false
        } catch {
            print("❌ Failed to send comment: \(error)")
        }
    }
}
