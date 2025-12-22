import SwiftUI

/// Barre d'actions réutilisable avec boutons de like, commentaire et partage
struct PostActionBar: View {
    @Binding var showComments: Bool
    
    let likeCount: Int
    let commentCount: Int
    let isLiked: Bool
    
    var onLike: () -> Void
    var onShare: () -> Void
    
    var body: some View {
        HStack(spacing: 24) {
            // Bouton Like
            Button(action: onLike) {
                HStack(spacing: 6) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundStyle(isLiked ? .red : .primary)
                    
                    if likeCount > 0 {
                        Text("\(likeCount)")
                            .font(.subheadline)
                    }
                }
            }
            .buttonStyle(.plain)
            
            // Bouton Commentaire
            Button {
                showComments = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "bubble.left")
                    
                    if commentCount > 0 {
                        Text("\(commentCount)")
                            .font(.subheadline)
                    }
                }
            }
            .buttonStyle(.plain)
            
            // Bouton Partage
            Button(action: onShare) {
                Image(systemName: "square.and.arrow.up")
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .font(.title3)
        .padding(.vertical, 8)
    }
}

/// Exemple de card de post avec barre d'actions
struct PostCardView: View {
    @State private var showComments = false
    @State private var isLiked = false
    @State private var likeCount = 42
    @State private var commentCount = 12
    
    let postId: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // En-tête du post
            HStack {
                Circle()
                    .fill(Color.blue.gradient)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Text("JD")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Jean Dupont")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("Il y a 2 heures")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button {
                    // Menu options
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.secondary)
                }
            }
            
            // Contenu du post
            Text("Magnifique coucher de soleil aujourd'hui ! 🌅")
                .font(.body)
            
            // Image du post (optionnel)
            Rectangle()
                .fill(Color.orange.gradient)
                .frame(height: 200)
                .cornerRadius(12)
                .overlay {
                    Image(systemName: "photo")
                        .font(.system(size: 50))
                        .foregroundStyle(.white.opacity(0.5))
                }
            
            Divider()
            
            // Barre d'actions
            PostActionBar(
                showComments: $showComments,
                likeCount: likeCount,
                commentCount: commentCount,
                isLiked: isLiked
            ) {
                // Action Like
                withAnimation {
                    isLiked.toggle()
                    likeCount += isLiked ? 1 : -1
                }
            } onShare: {
                // Action Partage
                print("Partager le post")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview("Post Card") {
    ScrollView {
        VStack(spacing: 16) {
            PostCardView(postId: "1")
            PostCardView(postId: "2")
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Action Bar") {
    PostActionBar(
        showComments: .constant(false),
        likeCount: 42,
        commentCount: 12,
        isLiked: false,
        onLike: {},
        onShare: {}
    )
    .padding()
}
