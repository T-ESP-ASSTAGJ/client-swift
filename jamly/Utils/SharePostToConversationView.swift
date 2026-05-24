import SwiftUI

private let accentGradient = LinearGradient(
    colors: [Color.appAccentPurple, Color.appAccentPink],
    startPoint: .leading,
    endPoint: .trailing
)

struct SharePostToConversationView: View {
    let post: Post

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userStore: UserStore
    @StateObject private var viewModel = ShareToConversationViewModel()

    @State private var searchText = ""
    @State private var selectedConversationId: Int?
    @State private var selectedUserId: Int?
    @State private var isSharing = false
    @State private var shareError: String?
    @State private var shareSuccess = false
    @State private var searchedUsers: [SearchUser] = []
    @State private var isSearchingUsers = false
    @State private var searchTask: Task<Void, Never>?
    @State private var activeTab: ShareTab = .conversations

    enum ShareTab {
        case conversations
        case users
    }

    private var filteredConversations: [ConversationPreview] {
        if searchText.isEmpty {
            return viewModel.conversations
        }
        return viewModel.conversations.filter { conversation in
            conversation.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var isSelectionMade: Bool {
        selectedConversationId != nil || selectedUserId != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    postPreview
                        .padding()

                    Divider()
                        .background(Color.gray.opacity(0.3))

                    tabPicker
                        .padding(.horizontal)
                        .padding(.top, 12)

                    searchBar
                        .padding()

                    if activeTab == .conversations {
                        conversationsContent
                    } else {
                        usersContent
                    }
                }
            }
            .navigationTitle("Share Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.appAccentPink)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send") {
                        Task { await sharePost() }
                    }
                    .disabled(!isSelectionMade || isSharing)
                    .foregroundColor(!isSelectionMade ? .gray : .appAccentPink)
                }
            }
            .task { await viewModel.loadConversations(currentUserId: userStore.user?.id ?? 0) }
            .alert("Error", isPresented: .constant(shareError != nil)) {
                Button("OK") { shareError = nil }
            } message: {
                if let error = shareError {
                    Text(error)
                }
            }
            .overlay {
                if isSharing {
                    ZStack {
                        Color.black.opacity(0.5).ignoresSafeArea()
                        ProgressView().tint(.white).scaleEffect(1.5)
                    }
                }
            }
        }
        .overlay(alignment: .top) {
            if shareSuccess {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Post shared")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(red: 0.12, green: 0.12, blue: 0.14)))
                .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                .padding(.top, 50)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(1)
            }
        }
    }

    // MARK: - Subviews

    private var tabPicker: some View {
        HStack(spacing: 0) {
            tabButton(title: "Conversations", tab: .conversations)
            tabButton(title: "Users", tab: .users)
        }
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }

    private func tabButton(title: String, tab: ShareTab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                activeTab = tab
                selectedConversationId = nil
                selectedUserId = nil
            }
        } label: {
            Text(title)
                .font(.subheadline.weight(activeTab == tab ? .semibold : .regular))
                .foregroundColor(activeTab == tab ? .white : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(activeTab == tab ? accentGradient : LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing))
                .cornerRadius(10)
        }
    }

    private var postPreview: some View {
        HStack(spacing: 16) {
            CachedAsyncImage(
                url: URL(string: post.frontImage),
                targetSize: CGSize(width: 60, height: 60)
            ) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundColor(.white)
                    }
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(post.track.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(post.user.username)
                    .font(.caption)
                    .foregroundColor(.secondary)
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
            TextField(
                activeTab == .conversations ? "Search conversations" : "Search users",
                text: $searchText
            )
            .foregroundColor(.white)
            .autocorrectionDisabled()
            .onChange(of: searchText) { _, newValue in
                if activeTab == .users {
                    debouncedUserSearch(query: newValue)
                }
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }

    // MARK: - Conversations Tab

    @ViewBuilder
    private var conversationsContent: some View {
        if viewModel.isLoading {
            Spacer()
            ProgressView().tint(.white)
            Spacer()
        } else if filteredConversations.isEmpty {
            emptyView(message: searchText.isEmpty ? "No conversations" : "No results found")
        } else {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredConversations) { conversation in
                        ShareConversationRow(
                            conversation: conversation,
                            isSelected: selectedConversationId == conversation.id,
                            onTap: { selectedConversationId = conversation.id }
                        )
                    }
                }
                .padding()
            }
        }
    }

    // MARK: - Users Tab

    @ViewBuilder
    private var usersContent: some View {
        if isSearchingUsers {
            Spacer()
            ProgressView().tint(.white)
            Spacer()
        } else if searchText.isEmpty {
            emptyView(message: "Search for a user")
        } else if searchedUsers.isEmpty {
            emptyView(message: "No users found")
        } else {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(searchedUsers) { user in
                        ShareUserRow(
                            user: user,
                            isSelected: selectedUserId == user.id,
                            onTap: { selectedUserId = user.id }
                        )
                    }
                }
                .padding()
            }
        }
    }

    private func emptyView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: activeTab == .conversations ? "message.slash" : "person.slash")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text(message)
                .foregroundColor(.secondary)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Actions

    private func debouncedUserSearch(query: String) {
        searchTask?.cancel()
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchedUsers = []
            return
        }
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            isSearchingUsers = true
            do {
                let response = try await SearchAction.searchUsers(username: query)
                if !Task.isCancelled {
                    searchedUsers = response.value
                }
            } catch {
                if !Task.isCancelled {
                    searchedUsers = []
                }
            }
            isSearchingUsers = false
        }
    }

    private func sharePost() async {
        isSharing = true
        defer { isSharing = false }

        do {
            var conversationId: Int

            if let id = selectedConversationId {
                conversationId = id
            } else if let userId = selectedUserId {
                let response = try await ConversationAction.createConversation(
                    isGroup: false,
                    groupName: nil,
                    participants: [userId]
                )
                conversationId = response.value.id
            } else {
                return
            }

            _ = try await MessageAction.sendPostMessage(
                conversationId: conversationId,
                postId: post.id
            )
            withAnimation(.easeOut(duration: 0.3)) { shareSuccess = true }
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            dismiss()
        } catch {
            shareError = error.localizedDescription
        }
    }
}

// MARK: - Share User Row

struct ShareUserRow: View {
    let user: SearchUser
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                if let avatarURL = user.profilePicture {
                    AsyncImage(url: URL(string: avatarURL)) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Circle().fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay {
                            Image(systemName: "person.fill")
                                .foregroundColor(.white.opacity(0.5))
                        }
                }

                Text(user.username)
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

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
                            .stroke(isSelected ? Color.appAccentPurple : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
