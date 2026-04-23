import SwiftUI

struct CommentRow: View {
    let comment: CommentResponse
    let isHighlighted: Bool

    @State private var isLiked: Bool
    @State private var likesCount: Int
    @State private var isTogglingLike: Bool = false

    init(comment: CommentResponse, isHighlighted: Bool = false) {
        self.comment = comment
        self.isHighlighted = isHighlighted
        self._isLiked = State(initialValue: comment.isLiked)
        self._likesCount = State(initialValue: comment.likesCount)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.blue.gradient)
                .frame(width: 40, height: 40)
                .overlay {
                    if let avatarURL = comment.user.profilePicture {
                        AsyncImage(url: URL(string: avatarURL)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Text(comment.user.username.prefix(1))
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                        .clipShape(Circle())
                    } else {
                        Text(comment.user.username.prefix(1))
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                }
            
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Text(comment.user.username)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    if let createdAt = comment.createdAt,
                       let date = ISO8601DateFormatter().date(from: createdAt) {
                        Text(relativeTimeString(from: date))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Right now")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Text(comment.content)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: 16) {
                    Button {
                        Task {
                            await toggleLike()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .foregroundStyle(isLiked ? .red : .secondary)
                            
                            if likesCount > 0 {
                                Text("\(likesCount)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isTogglingLike)
                    
//                    Button {
//                        // TODO: Action pour répondre
//                    } label: {
//                        Text("Answer")
//                            .font(.caption)
//                            .foregroundStyle(.secondary)
//                    }
//                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isHighlighted ? Color(.systemGray3) : Color(.systemGray6))
        )
    }
    
    private func toggleLike() async {
        guard !isTogglingLike else { return }
        
        isTogglingLike = true
        
        let previousLikedState = isLiked
        let previousLikesCount = likesCount
        
        withAnimation(.spring(response: 0.3)) {
            isLiked.toggle()
            likesCount += isLiked ? 1 : -1
        }
        
        do {
            if isLiked {
                _ = try await CommentAction.like(commentId: comment.id)
            } else {
                _ = try await CommentAction.unlike(commentId: comment.id)
            }
        } catch {
            withAnimation(.spring(response: 0.3)) {
                isLiked = previousLikedState
                likesCount = previousLikesCount
            }
            print("Error toggling like: \(error)")
        }
        
        isTogglingLike = false
    }
    
    // MARK: - Helper Methods
    
    private func relativeTimeString(from date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        let seconds = Int(timeInterval)
        let minutes = seconds / 60
        let hours = minutes / 60
        let days = hours / 24
        let weeks = days / 7
        let months = days / 30
        let years = days / 365
        
        if years > 0 {
            return years == 1 ? "1 year ago" : "\(years) years ago"
        } else if months > 0 {
            return months == 1 ? "1 month ago" : "\(months) months ago"
        } else if weeks > 0 {
            return weeks == 1 ? "1 week ago" : "\(weeks) weeks ago"
        } else if days > 0 {
            return days == 1 ? "1 day ago" : "\(days) days ago"
        } else if hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else if minutes > 0 {
            return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
        } else {
            return seconds <= 5 ? "Right now" : "\(seconds) seconds ago"
        }
    }
}
