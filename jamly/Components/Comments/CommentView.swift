import SwiftUI

struct CommentView: View {
    let comment: CommentType
    
    @State private var isLiked = false
    @State private var likeCount = 0
    @State private var showReplySheet = false
    
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
                    
                    if let date = ISO8601DateFormatter().date(from: comment.createdAt) {
                        Text(relativeTimeString(from: date))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(comment.createdAt)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Text(comment.content)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: 16) {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            isLiked.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .foregroundStyle(isLiked ? .red : .secondary)
                            
                            if likeCount + (isLiked ? 1 : 0) > 0 {
                                Text("\(likeCount + (isLiked ? 1 : 0))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        // TODO: Action pour répondre
                    } label: {
                        Text("Answer")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
            }
            Spacer()
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
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


// MARK: - Preview

#Preview("Single Comment") {
    CommentView(
        comment: CommentType(
            id: 1,
            user: User(
                id: 1,
                username: "testuser",
                email: "test@test.fr",
                profilePicture:"https://fastly.picsum.photos/id/426/200/200.jpg?hmac=5auPuax0L2lXSIX0eJ2Qxa3HzmGUHCrGDPIEMAWgw7o"
            ),
            content: "Hello, world!",
            createdAt: "2025-12-12T14:30:00Z"
        )
    )
    .padding()
    .preferredColorScheme(ColorScheme.dark)
}
