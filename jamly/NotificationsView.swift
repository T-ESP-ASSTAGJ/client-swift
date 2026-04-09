//
//  NotificationsView.swift
//  jamly
//
//  Created by Jonathan Dumesnil on 20/03/2026.
//

import SwiftUI

// MARK: - Notification Model
struct AppNotification: Identifiable {
    let id: String
    let type: NotificationType
    let senderUsername: String
    let senderProfilePicture: String?
    let postThumbnail: String?
    let message: String
    let timestamp: Date
    var isRead: Bool
    
    // IDs pour la navigation
    let postId: String?
    let userId: String?
}

enum NotificationType {
    case like
    case comment
    case follow
    case mention
    
    var icon: String {
        switch self {
        case .like: return "heart.fill"
        case .comment: return "bubble.left.fill"
        case .follow: return "person.fill.badge.plus"
        case .mention: return "at"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .like: return .red
        case .comment: return .blue
        case .follow: return .green
        case .mention: return .orange
        }
    }
}

// MARK: - Notifications View
struct NotificationsView: View {
    @State private var notifications: [AppNotification] = []
    @State private var selectedNotification: AppNotification?
    @State private var showingProfile = false
    @State private var selectedUserId: Int?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fond de l'app (noir ou systemBackground selon le mode)
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()
                
                if notifications.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(notifications) { notification in
                                NotificationRow(notification: notification) {
                                    handleNotificationTap(notification)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(notification.isRead ? Color.clear : Color.blue.opacity(0.05))
                                .transition(.opacity.combined(with: .move(edge: .trailing)))
                                
                                if notification.id != notifications.last?.id {
                                    Divider()
                                        .padding(.leading, 68)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !notifications.isEmpty && notifications.contains(where: { !$0.isRead }) {
                        Button {
                            withAnimation {
                                markAllAsRead()
                            }
                        } label: {
                            Text("Tout lire")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $showingProfile) {
                if let userId = selectedUserId {
                    ProfileView(userId: userId)
                }
            }
            .task {
                loadNotifications()
                await NotificationManager.shared.resetBadge()
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.badge")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.5))
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: 8) {
                Text("Aucune notification")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Quand quelqu'un aime ou commente vos posts,\nvous le verrez ici.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(40)
    }
    
    // MARK: - Actions
    private func loadNotifications() {
        // TODO: Remplacer par un appel API
        notifications = generateFakeNotifications()
    }
    
    private func markAllAsRead() {
        for index in notifications.indices {
            notifications[index].isRead = true
        }
        // TODO: Appeler l'API pour marquer comme lu
    }
    
    private func handleNotificationTap(_ notification: AppNotification) {
        // Marquer comme lu avec animation
        withAnimation {
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[index].isRead = true
            }
        }
        
        // Navigation selon le type
        switch notification.type {
        case .like, .comment, .mention:
            // TODO: Naviguer vers le post
            print("📱 Naviguer vers le post: \(notification.postId ?? "")")
            
        case .follow:
            // Naviguer vers le profil
            if let userIdString = notification.userId,
               let userId = Int(userIdString) {
                selectedUserId = userId
                showingProfile = true
            }
        }
    }
}

// MARK: - Notification Row
struct NotificationRow: View {
    let notification: AppNotification
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 12) {
                // Photo de profil avec badge
                ZStack(alignment: .bottomTrailing) {
                    // Photo de profil
                    if let profilePic = notification.senderProfilePicture {
                        AsyncImage(url: URL(string: profilePic)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .overlay {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.gray)
                                }
                        }
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 44, height: 44)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.gray)
                            }
                    }
                    
                    // Icône du type de notification (sans fond)
                    Image(systemName: notification.type.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(notification.type.iconColor)
                        .offset(x: 4, y: 4)
                        .shadow(color: Color(uiColor: .systemBackground), radius: 3, x: 0, y: 0)
                }
                
                // Contenu de la notification
                VStack(alignment: .leading, spacing: 4) {
                    Text(buildAttributedMessage())
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(notification.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Thumbnail du post (si applicable)
                if let thumbnail = notification.postThumbnail {
                    AsyncImage(url: URL(string: thumbnail)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // Indicateur non lu
                if !notification.isRead {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
    }
    
    private func buildAttributedMessage() -> AttributedString {
        var attributedString = AttributedString(notification.senderUsername)
        attributedString.font = .subheadline.weight(.semibold)
        
        var messageString = AttributedString(" " + notification.message)
        messageString.font = .subheadline
        messageString.foregroundColor = .secondary
        
        return attributedString + messageString
    }
}

// MARK: - Fake Data Generator
private func generateFakeNotifications() -> [AppNotification] {
    let now = Date()
    
    return [
        AppNotification(
            id: "1",
            type: .like,
            senderUsername: "alice_m",
            senderProfilePicture: nil,
            postThumbnail: nil,
            message: "liked your post",
            timestamp: now.addingTimeInterval(-300), // 5 min ago
            isRead: false,
            postId: "post123",
            userId: "1"
        ),
        AppNotification(
            id: "2",
            type: .comment,
            senderUsername: "bob_jones",
            senderProfilePicture: nil,
            postThumbnail: nil,
            message: "commented: \"This is amazing! 🔥\"",
            timestamp: now.addingTimeInterval(-1800), // 30 min ago
            isRead: false,
            postId: "post124",
            userId: "2"
        ),
        AppNotification(
            id: "3",
            type: .follow,
            senderUsername: "charlie_dev",
            senderProfilePicture: nil,
            postThumbnail: nil,
            message: "started following you",
            timestamp: now.addingTimeInterval(-3600), // 1h ago
            isRead: true,
            postId: nil,
            userId: "3"
        ),
        AppNotification(
            id: "4",
            type: .like,
            senderUsername: "diana_art",
            senderProfilePicture: nil,
            postThumbnail: nil,
            message: "liked your post",
            timestamp: now.addingTimeInterval(-7200), // 2h ago
            isRead: true,
            postId: "post125",
            userId: "4"
        ),
        AppNotification(
            id: "5",
            type: .mention,
            senderUsername: "evan_music",
            senderProfilePicture: nil,
            postThumbnail: nil,
            message: "mentioned you in a post",
            timestamp: now.addingTimeInterval(-86400), // 1 day ago
            isRead: true,
            postId: "post126",
            userId: "5"
        ),
        AppNotification(
            id: "6",
            type: .comment,
            senderUsername: "fiona_photo",
            senderProfilePicture: nil,
            postThumbnail: nil,
            message: "commented: \"Love this! 💕\"",
            timestamp: now.addingTimeInterval(-172800), // 2 days ago
            isRead: true,
            postId: "post127",
            userId: "6"
        ),
        AppNotification(
            id: "7",
            type: .like,
            senderUsername: "george_fit",
            senderProfilePicture: nil,
            postThumbnail: nil,
            message: "liked your post",
            timestamp: now.addingTimeInterval(-259200), // 3 days ago
            isRead: true,
            postId: "post128",
            userId: "7"
        ),
        AppNotification(
            id: "8",
            type: .follow,
            senderUsername: "hannah_travel",
            senderProfilePicture: nil,
            postThumbnail: nil,
            message: "started following you",
            timestamp: now.addingTimeInterval(-345600), // 4 days ago
            isRead: true,
            postId: nil,
            userId: "8"
        ),
    ]
}

#Preview {
    NotificationsView()
}
