//
//  ChatsView.swift
//  jamly
//
//  Created by REVERSS on 08/12/2025.
//

import SwiftUI
import Combine

// MARK: - Conversation Row

struct ConversationRow: View {
    @EnvironmentObject private var userStore: UserStore
    let conversation: Conversation
    
    // Computed property pour obtenir l'ID de l'utilisateur courant
    private var currentUserId: Int {
        userStore.user?.id ?? 0
    }
    
    // Computed property pour le nom d'affichage
    private var displayName: String {
        conversation.displayName(currentUserId: currentUserId)
    }
    
    // Computed property pour l'autre participant (si conversation directe)
    private var otherUser: CommonUser? {
        conversation.otherParticipant(currentUserId: currentUserId)
    }
    
    var body: some View {
        HStack(spacing: 15) {
            // Avatar
            avatarView
            
            // Infos
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(displayName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        // Timestamp
                        if let lastMessage = conversation.lastMessage {
                            Text(formatTimestamp(lastMessage))
                                .font(.footnote)
                                .foregroundColor(.gray)
                        } else {
                            Text("New")
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    if let lastMessage = conversation.lastMessage {
                        Text(formatLastMessage(lastMessage, isGroup: conversation.isGroup))
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .multilineTextAlignment(.leading)
                    } else {
                        Text("No messages yet")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .italic()
                    }
                    
                    Spacer()
                    
                    // Badge de messages non lus
                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .frame(height: 60)
    }
    
    // MARK: - Avatar View
    
    @ViewBuilder
    private var avatarView: some View {
        if conversation.isGroup {
            GroupAvatarView(size: 44)
        } else {
            AvatarView(profilePicture: otherUser?.profilePicture, size: 44)
        }
    }
    
    // MARK: - Helpers
    
    private func formatLastMessage(_ message: LightMessage, isGroup: Bool) -> String {
        if isGroup {
            return "\(message.author.username): \(message.displayPreview)"
        }
        return message.displayPreview
    }
    
    private func formatTimestamp(_ message: LightMessage) -> String {
        // Parser la date string (format ISO8601)
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: message.createdAt) else {
            return "New"
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            // Aujourd'hui: afficher l'heure
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            return timeFormatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if let daysDiff = calendar.dateComponents([.day], from: date, to: now).day, daysDiff < 7 {
            // Cette semaine: afficher le jour
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEEE"
            return dayFormatter.string(from: date)
        } else {
            // Plus ancien: afficher la date
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            return dateFormatter.string(from: date)
        }
    }
}

// MARK: - Main View

struct ChatsView: View {
    @StateObject private var viewModel = ChatsViewModel()
    @State private var selectedConversation: Conversation?
    @State private var showNewConversation = false
    @State private var conversationToDelete: Conversation?
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        ZStack {
            // Liste des conversations
            conversationsList
            
            // État de chargement
            if viewModel.isLoading && viewModel.conversations.isEmpty {
                ProgressView("Loading...")
                    .tint(.white)
            }
        }
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search for a chat"
        )
        .navigationTitle("Chats")
        .navigationDestination(item: $selectedConversation) { conversation in
            ChatDetailView(conversation: conversation)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showNewConversation = true
                } label: {
                    Image(systemName: "square.and.pencil")
                        .foregroundColor(.white)
                }
            }
        }
        .sheet(isPresented: $showNewConversation, onDismiss: {
            // Rafraîchir la liste des conversations après création
            Task {
                await viewModel.refresh()
            }
        }) {
            NewConversationView()
        }
        .task {
            await viewModel.loadConversations()
        }
        .refreshable {
            await viewModel.refresh()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .alert("Delete chat", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                conversationToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let conversation = conversationToDelete {
                    deleteConversation(conversation)
                }
                conversationToDelete = nil
            }
        } message: {
            if conversationToDelete != nil {
                Text("Are you sure you want to delete this conversation?")
            }
        }
    }
    
    // MARK: - Conversations List
    
    @ViewBuilder
    private var conversationsList: some View {
        if viewModel.filteredConversations.isEmpty && !viewModel.isLoading {
            emptyState
        } else {
            List(viewModel.filteredConversations) { conversation in
                Button {
                    selectedConversation = conversation
                } label: {
                    ConversationRow(conversation: conversation)
                }
                .buttonStyle(.borderless)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden, edges: .top)
                .listRowSeparator(
                    conversation.id == viewModel.filteredConversations.last?.id ? .hidden : .visible,
                    edges: .bottom
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        conversationToDelete = conversation
                        showDeleteConfirmation = true
                    } label: {
                        Label("Supprimer", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button {
                        toggleReadStatus(conversation)
                    } label: {
                        Label(
                            conversation.unreadCount > 0 ? "Mark as read" : "Mark as unread",
                            systemImage: conversation.unreadCount > 0 ? "envelope.open" : "envelope.badge"
                        )
                    }
                    .tint(.blue)
                }
                .onAppear {
                    if viewModel.shouldLoadMore(for: conversation) {
                        Task {
                            await viewModel.loadMoreConversations()
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.plain)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        Group {
            if viewModel.searchText.isEmpty {
                EmptyStateView(
                    icon: "bubble.left.and.bubble.right.fill",
                    title: "No chats yet",
                    subtitle: "Start a conversation with someone you follow.",
                    action: .init(
                        label: "New chat",
                        icon: "plus",
                        handler: { showNewConversation = true }
                    )
                )
            } else {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "No conversations match",
                    subtitle: "Try searching for a different name."
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    
    /// Supprime une conversation
    private func deleteConversation(_ conversation: Conversation) {
        Task {
            await viewModel.deleteConversation(conversation)
        }
    }
    
    /// Basculer le statut lu/non lu d'une conversation
    private func toggleReadStatus(_ conversation: Conversation) {
        Task {
            await viewModel.toggleReadStatus(conversation)
        }
    }
}
// MARK: - New Conversation View

struct NewConversationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = NewConversationViewModel()
    @FocusState private var isGroupNameFocused: Bool

    var isGroup: Bool { viewModel.selectedUsers.count > 1 }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Chips des utilisateurs sélectionnés
                if !viewModel.selectedUsers.isEmpty {
                    HStack(spacing: 8) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(viewModel.selectedUsers) { user in
                                    SelectedUserChip(user: user) {
                                        viewModel.toggleUserSelection(user)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .frame(height: 52)
                    .background(Color(uiColor: .systemBackground))
                }

                // Nom du groupe (affiché uniquement si groupe)
                if isGroup {
                    TextField("Group name", text: $viewModel.groupName)
                        .focused($isGroupNameFocused)
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                        .background(Color(uiColor: .systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(uiColor: .systemBackground))
                }

                Divider()

                // Liste des followers
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading...")
                        .tint(.white)
                    Spacer()
                } else if viewModel.filteredFollowers.isEmpty {
                    emptyFollowersView
                } else {
                    followersList
                }
            }
            .navigationTitle("New chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isCreating {
                        ProgressView().tint(.white)
                    } else {
                        Button(isGroup ? "Create group" : "Start chat") {
                            Task {
                                await viewModel.createConversation()
                                if viewModel.conversationCreated { dismiss() }
                            }
                        }
                        .disabled(!viewModel.canCreate)
                        .fontWeight(.semibold)
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search followers")
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                if let error = viewModel.errorMessage { Text(error) }
            }
            .task { await viewModel.loadFollowers() }
            .onChange(of: isGroup) { if isGroup { isGroupNameFocused = true } }
        }
    }

    // MARK: - Followers List

    private var followersList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.filteredFollowers) { follower in
                    let isSelected = viewModel.selectedUsers.contains(where: { $0.id == follower.id })
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.toggleUserSelection(follower)
                        }
                    } label: {
                        FollowerRow(follower: follower, isSelected: isSelected)
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)

                    if follower.id != viewModel.filteredFollowers.last?.id {
                        Divider()
                            .padding(.leading, 72)
                    }
                }
            }
        }
        // Le ScrollView consomme le swipe-down via .refreshable, ce qui empêche la sheet
        // de se fermer par accident quand l'utilisateur veut juste rafraîchir la liste.
        .refreshable {
            await viewModel.loadFollowers()
        }
    }

    // MARK: - Empty State

    private var emptyFollowersView: some View {
        VStack {
            Spacer()
            EmptyStateView(
                icon: "person.2.slash",
                title: "No followers yet",
                subtitle: "Follow people first — then you can start chats with them."
            )
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Selected User Chip

struct SelectedUserChip: View {
    let user: FollowingUser
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            AvatarView(profilePicture: user.profilePicture, size: 22)

            Text(user.username)
                .font(.subheadline)
                .foregroundColor(.primary)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .glassEffect(.regular.interactive(), in: .capsule)
    }
}

// MARK: - Follower Row

struct FollowerRow: View {
    let follower: FollowingUser
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(profilePicture: follower.profilePicture, size: 44)

            Text(follower.username)
                .font(.headline)
                .foregroundColor(.white)

            Spacer()

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(
                    isSelected
                        ? AnyShapeStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.6, green: 0.4, blue: 0.9),
                                    Color(red: 0.8, green: 0.4, blue: 0.7)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        : AnyShapeStyle(Color.gray)
                )
                .font(.title3)
                .animation(.spring(response: 0.2), value: isSelected)
        }
    }
}

// MARK: - New Conversation ViewModel

@MainActor
class NewConversationViewModel: ObservableObject {
    @Published var followers: [FollowingUser] = []
    @Published var filteredFollowers: [FollowingUser] = []
    @Published var selectedUsers: [FollowingUser] = []
    @Published var isLoading = false
    @Published var isCreating = false
    @Published var errorMessage: String?
    @Published var groupName: String = ""
    @Published var searchText = "" {
        didSet { filterFollowers() }
    }
    @Published var conversationCreated = false

    // MARK: - Computed

    var isGroup: Bool { selectedUsers.count > 1 }

    var canCreate: Bool {
        guard !selectedUsers.isEmpty else { return false }
        if isGroup {
            return !groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return true
    }

    // MARK: - Load Followers

    func loadFollowers() async {
        isLoading = true
        errorMessage = nil

        do {
            let meResponse = try await UserActions.fetchMe()
            let currentUserId = meResponse.value.id
            let response = try await FollowingAction.getFollowingUsers(userId: currentUserId)
            followers = response.value
            filterFollowers()
            print("✅ Loaded \(followers.count) followers")
        } catch {
            errorMessage = "Failed to load followers"
            print("❌ Error loading followers: \(error)")
        }

        isLoading = false
    }

    // MARK: - Filter Followers

    private func filterFollowers() {
        if searchText.isEmpty {
            filteredFollowers = followers
        } else {
            filteredFollowers = followers.filter {
                $0.username.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    // MARK: - Toggle Selection

    func toggleUserSelection(_ user: FollowingUser) {
        if let index = selectedUsers.firstIndex(where: { $0.id == user.id }) {
            selectedUsers.remove(at: index)
        } else {
            selectedUsers.append(user)
        }
    }

    // MARK: - Create Conversation

    func createConversation() async {
        guard canCreate else { return }

        isCreating = true
        errorMessage = nil
        conversationCreated = false

        do {
            let participantIds = selectedUsers.map { $0.id }
            let finalGroupName = isGroup
                ? groupName.trimmingCharacters(in: .whitespacesAndNewlines)
                : nil

            let response = try await ConversationAction.createConversation(
                isGroup: isGroup,
                groupName: finalGroupName,
                participants: participantIds
            )

            print("✅ Conversation created: \(response.value.id)")
            conversationCreated = true
        } catch {
            errorMessage = "Failed to create conversation"
            print("❌ Error creating conversation: \(error)")
        }

        isCreating = false
    }
}


