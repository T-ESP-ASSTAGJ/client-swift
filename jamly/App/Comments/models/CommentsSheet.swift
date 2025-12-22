//
//  CommentsSheet.swift
//  jamly
//
//  Created by Jonathan Dumesnil on 21/12/2025.
//

import SwiftUI

struct CommentsSheet: View {
    let post: JamPost
    @Environment(\.dismiss) private var dismiss
    @State private var comments: [CommentType] = CommentType.mockComments
    @State private var newCommentText: String = ""
    @State private var isLoading: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                postHeader
                
                Divider()
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if comments.isEmpty && !isLoading {
                            emptyStateView
                        } else {
                            ForEach(comments) { comment in
                                CommentView(comment: comment)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
                
                Divider()
                
                commentInputSection
            }
            .navigationTitle("Comments")
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
                await loadComments()
            }
        }
    }
    
    // MARK: - Post Header
    
    private var postHeader: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: post.coverImageName)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(post.title)
                    .font(.headline)
                    .textCase(.uppercase)
                Text(post.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("Aucun commentaire")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("Soyez le premier à commenter!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
    
    // MARK: - Comment Input Section
    
    private var commentInputSection: some View {
        HStack(alignment: .bottom, spacing: 12) {
            TextField("Write a comment...", text: $newCommentText, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color(.systemGray6))
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
    
    // MARK: - Methods
    
    private func loadComments() async {
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Remplacer par un appel API pour charger les commentaires du post
        try? await Task.sleep(for: .seconds(0.5))
        
        comments = CommentType.mockComments
    }
    
    private func sendComment() async {
        let trimmedText = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Remplacer par un appel API pour poster le commentaire
        try? await Task.sleep(for: .seconds(0.5))
        
        let newComment = CommentType(
            id: comments.count + 1,
            user: User(
                id: 0,
                username: "Me",
                email: "me@test.fr",
                profilePicture: nil
            ),
            content: trimmedText,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        
        withAnimation {
            comments.insert(newComment, at: 0)
        }
        
        // Reset text field
        newCommentText = ""
        isTextFieldFocused = false
    }
}

// MARK: - Preview
#Preview {
    CommentsSheet(post: JamPost.mock[0])
        .preferredColorScheme(.dark)
}
