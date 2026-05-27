import SwiftUI
import MusicKit
import Combine

// MARK: - App Accent Colors
extension Color {
    static let appAccentPurple = Color(red: 0.6, green: 0.4, blue: 0.9)
    static let appAccentPink = Color(red: 0.8, green: 0.4, blue: 0.7)
}

/// View to share a playlist to a specific conversation
struct ShareToConversationView: View {
    let playlist: Playlist
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userStore: UserStore
    private let shareService = PlaylistShareService.shared
    @StateObject private var viewModel = ShareToConversationViewModel()
    
    @State private var searchText = ""
    @State private var selectedConversationId: Int?
    @State private var isSharing = false
    @State private var shareError: String?
    @State private var shareSuccess = false
    
    var filteredConversations: [ConversationPreview] {
        if searchText.isEmpty {
            return viewModel.conversations
        }
        return viewModel.conversations.filter { conversation in
            conversation.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Playlist Preview
                    playlistPreview
                        .padding()
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    // Search Bar
                    searchBar
                        .padding()
                    
                    // Conversations List
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .tint(.white)
                        Spacer()
                    } else if filteredConversations.isEmpty {
                        emptyView
                    } else {
                        conversationsList
                    }
                }
            }
            .navigationTitle("Send to Conversation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.appAccentPink)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send") {
                        Task { await sharePlaylist() }
                    }
                    .disabled(selectedConversationId == nil || isSharing)
                    .foregroundColor(selectedConversationId == nil ? .gray : .pink)
                }
            }
            .task {
                await viewModel.loadConversations(currentUserId: userStore.user?.id ?? 0)
            }
            .alert("Share Playlist", isPresented: $shareSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Playlist shared successfully!")
            }
            .alert("Error", isPresented: .constant(shareError != nil)) {
                Button("OK") {
                    shareError = nil
                }
            } message: {
                if let error = shareError {
                    Text(error)
                }
            }
            .overlay {
                if isSharing {
                    ZStack {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                        
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.5)
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var playlistPreview: some View {
        HStack(spacing: 16) {
            if let artwork = playlist.artwork {
                ArtworkImage(artwork, width: 60, height: 60)
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "music.note.list")
                            .foregroundColor(.white)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Image(systemName: "applelogo")
                        .font(.caption)
                        .foregroundColor(.appAccentPink)
                    Text("Apple Music")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search conversations", text: $searchText)
                .foregroundColor(.white)
                .autocorrectionDisabled()
        }
        .padding(12)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
    
    private var conversationsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(filteredConversations) { conversation in
                    ShareConversationRow(
                        conversation: conversation,
                        isSelected: selectedConversationId == conversation.id,
                        onTap: {
                            selectedConversationId = conversation.id
                        }
                    )
                }
            }
            .padding()
        }
    }
    
    private var emptyView: some View {
        Group {
            if searchText.isEmpty {
                EmptyStateView(
                    icon: "bubble.left.and.bubble.right.fill",
                    title: "No conversations yet",
                    subtitle: "Start a chat to share this here."
                )
            } else {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "No matches",
                    subtitle: "Nothing matches \"\(searchText)\"."
                )
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Actions
    
    private func sharePlaylist() async {
        guard let conversationId = selectedConversationId else { return }
        
        isSharing = true
        defer { isSharing = false }
        
        do {
            try await shareService.sharePlaylistToConversation(
                playlist,
                conversationId: conversationId
            )
            shareSuccess = true
        } catch let error as APIError {
            if error.isPossiblePartialSuccess {
                shareSuccess = true
            } else {
                shareError = error.errorDescription ?? error.localizedDescription
            }
        } catch {
            shareError = error.localizedDescription
        }
    }
}

// MARK: - Share Conversation Row

struct ShareConversationRow: View {
    let conversation: ConversationPreview
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Avatar
                if let avatarURL = conversation.avatarURL {
                    AsyncImage(url: URL(string: avatarURL)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.white.opacity(0.5))
                        )
                }
                
                // Conversation Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(conversation.displayName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if let lastMessage = conversation.lastMessage {
                        Text(lastMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.appAccentPink)
                        .font(.title2)
                }
            }
            .padding()
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.15) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? .appAccentPurple : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - ViewModel

@MainActor
class ShareToConversationViewModel: ObservableObject {
    @Published var conversations: [ConversationPreview] = []
    @Published var isLoading = false
    @Published var error: String?
    
    func loadConversations(currentUserId: Int) async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Load conversations from API
            let response = try await ConversationAction.getConversations()
            conversations = response.value.map { ConversationPreview(from: $0, currentUserId: currentUserId) }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Models

struct ConversationPreview: Identifiable {
    let id: Int
    let displayName: String
    let avatarURL: String?
    let lastMessage: String?

    init(from conversation: Conversation, currentUserId: Int) {
        self.id = conversation.id
        self.displayName = conversation.displayName(currentUserId: currentUserId)
        self.avatarURL = conversation.displayProfilePicture(currentUserId: currentUserId)
            ?? conversation.participants.first?.profilePicture
        self.lastMessage = conversation.lastMessage?.displayPreview
    }
}

#Preview {
    Text("Preview placeholder")
}
