//
//  ChatDetailView.swift
//  jamly
//
//  Created by REVERSS on 31/12/2025.
//

import SwiftUI
import Combine
import MusicKit

// Les modèles Conversation et ChatMessage sont dans ChatModels.swift

// MARK: - Message Bubble View
/// Bulle de message stylisée (texte ou musique)
struct MessageBubble: View {
    let message: Message
    let showSenderName: Bool // Pour les groupes
    let currentUserId: Int
    
    var isFromCurrentUser: Bool {
        message.isFromCurrentUser(currentUserId: currentUserId)
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isFromCurrentUser {
                Spacer()
            }
            
            // Avatar pour les messages reçus
            if !isFromCurrentUser, let profilePicture = message.author.profilePicture {
                AsyncImage(url: URL(string: profilePicture)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                // Nom de l'expéditeur (pour les groupes)
                if showSenderName, !isFromCurrentUser {
                    Text(message.author.username)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 4)
                }
                
                // Contenu du message
                if message.isMusicMessage {
                    // Bulle de message musical
                    MusicMessageView(message: message)
                } else if isPlaylistLink(message.content) {
                    PlaylistLinkMessageView(
                        message: message,
                        isFromCurrentUser: isFromCurrentUser
                    )
                } else {
                    // Bulle de message texte
                    Text(message.content ?? "")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(isFromCurrentUser ? Color.blue : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }
                
                // Timestamp + statut de lecture
                HStack(spacing: 4) {
                    Text(message.timeString)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 4)
            }
            
            if !isFromCurrentUser {
                Spacer()
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Helper Methods

    /// Check if message content is an Apple Music playlist link
    private func isPlaylistLink(_ content: String?) -> Bool {
        guard let content = content else { return false }
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.contains(Config.appleMusicHost) && trimmed.contains(Config.appleMusicPlaylistPath) { return true }
        // Legacy format: "🎵 Name\nURL"
        return content.contains("🎵") && content.contains(Config.appleMusicHost)
    }
}

// MARK: - Music Message View
/// Displays a track message. message.track holds the Apple Music catalog song ID.
/// Title, artist and artwork are fetched from MusicKit at display time.
struct MusicMessageView: View {
    let message: Message

    @EnvironmentObject private var musicManager: MusicManager

    @State private var songTitle: String = "Track"
    @State private var songArtist: String = "Apple Music"
    @State private var artwork: Artwork? = nil
    @State private var songURL: URL? = nil

    /// Extracts the Apple Music catalog song ID from the message content URL.
    /// Format: music.apple.com/album/.../id?i=songId
    var catalogSongID: String? {
        guard let content = message.content else { return nil }
        if let components = URLComponents(string: content),
           let songId = components.queryItems?.first(where: { $0.name == "i" })?.value {
            return songId
        }
        // Fallback: last numeric path component
        if let url = URL(string: content), let last = url.pathComponents.last,
           last.allSatisfy({ $0.isNumber }), !last.isEmpty {
            return last
        }
        return nil
    }

    var isThisPlaying: Bool {
        musicManager.isPlaying && musicManager.currentSongId == catalogSongID
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Group {
                    if let artwork {
                        ArtworkImage(artwork, width: 56, height: 56)
                    } else {
                        artworkPlaceholder
                    }
                }
                .frame(width: 56, height: 56)
                .cornerRadius(8)
                .clipped()

                VStack(alignment: .leading, spacing: 4) {
                    Text(songTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(songArtist)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Image(systemName: "applelogo").font(.caption2)
                        Text("Apple Music").font(.caption)
                    }
                    .foregroundColor(.white.opacity(0.6))
                }

                Spacer(minLength: 0)

                // Play/pause button
                if catalogSongID != nil {
                    Button {
                        Task { await togglePlayPause() }
                    } label: {
                        Image(systemName: isThisPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(12)

            Divider().background(Color.white.opacity(0.2))

            if let url = songURL {
                Link(destination: url) {
                    HStack {
                        Image(systemName: "arrow.up.right.square").font(.body)
                        Text("Open in Apple Music").font(.subheadline.weight(.semibold))
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
            }
        }
        .background(
            LinearGradient(
                colors: [Color.pink.opacity(0.7), Color.pink.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .frame(maxWidth: 300)
        .task(id: message.id) { await loadSongData() }
    }

    private var artworkPlaceholder: some View {
        Rectangle()
            .fill(Color.white.opacity(0.15))
            .overlay {
                Image(systemName: "music.note")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.6))
            }
    }

    private func togglePlayPause() async {
        guard let songID = catalogSongID else { return }
        if isThisPlaying {
            musicManager.pause()
        } else {
            await musicManager.playPreview(songId: songID)
        }
    }

    private func loadSongData() async {
        guard let songID = catalogSongID, !songID.isEmpty,
              MusicAuthorization.currentStatus == .authorized else { return }
        do {
            let request = MusicCatalogResourceRequest<Song>(
                matching: \.id, equalTo: MusicItemID(songID)
            )
            let response = try await request.response()
            guard let song = response.items.first else { return }
            songTitle = song.title
            songArtist = song.artistName
            artwork = song.artwork
            songURL = song.url
        } catch {
            // MusicKit fetch failed — UI keeps default placeholder values
        }
    }
}

// MARK: - Chat Detail View
struct ChatDetailView: View {
    let conversation: Conversation
    
    // État local
    @State private var messages: [Message] = []
    @State private var newMessageText: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var hasScrolledToBottom: Bool = false
    @State private var showPlaylistPicker = false
    @State private var showTrackPicker = false
    @FocusState private var isTextFieldFocused: Bool
    
    // ✅ Pour le debouncing du markAsRead
    @State private var markAsReadTask: Task<Void, Never>?

    // Dependencies
    @EnvironmentObject private var userStore: UserStore
    @StateObject private var mercureService = MercureService.shared
    
    private var currentUserId: Int {
        userStore.user?.id ?? 0
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Zone de messages avec défilement
            messageScrollView
            
            // Affichage d'erreur si nécessaire
            if let errorMessage {
                errorBanner(message: errorMessage)
            }
        }
        .safeAreaInset(edge: .bottom) {
            messageInputSection
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .navigationTitle(conversation.displayName(currentUserId: currentUserId))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                conversationHeader
            }
        }
        .onAppear {
            loadMessages()
            Task {
                _ = await (setupMercure(), markConversationAsRead())
            }
        }
        .onDisappear {
            mercureService.unsubscribe()
            // ✅ Annuler la tâche de markAsRead en cours si on quitte la vue
            markAsReadTask?.cancel()
        }
    }
    
    // MARK: - Mercure Setup
    
    /// Configure Mercure pour recevoir les messages en temps réel
    private func setupMercure() async {
        let topic = "/conversations/\(conversation.id)"
        
        await mercureService.subscribe(topics: [topic]) { receivedTopic, data in
            handleMercureMessage(data: data)
        }
    }
    
    /// Traite un message reçu via Mercure
    private func handleMercureMessage(data: Data) {
        do {
            let wrapper = try JSONDecoder().decode(MercureMessageWrapper.self, from: data)
            let newMessage = wrapper.message

            if newMessage.isFromCurrentUser(currentUserId: currentUserId) {
                if let tempIndex = messages.firstIndex(where: { $0.id == -1 }) {
                    messages[tempIndex] = newMessage
                } else if !messages.contains(where: { $0.id == newMessage.id }) {
                    messages.append(newMessage)
                }
            } else {
                if !messages.contains(where: { $0.id == newMessage.id }) {
                    messages.append(newMessage)
                    print("✅ Message ajouté (reçu d'un autre utilisateur)")

                    // ✅ Marquer automatiquement comme lu puisqu'on est dans le chat
                    // Utilise debouncing pour éviter trop d'appels réseau
                    markConversationAsReadDebounced()
                } else {
                    print("⚠️ Message déjà présent (ignoré)")
                }
            }
        } catch {
            // Mercure parse error — silently ignored
        }
    }
    
    // MARK: - Conversation Header
    
    private var conversationHeader: some View {
        HStack(spacing: 12) {
            // Photo de profil (pour les conversations directes)
            if let profilePicture = conversation.displayProfilePicture(currentUserId: currentUserId) {
                AsyncImage(url: URL(string: profilePicture)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            } else if conversation.isGroup {
                // Icône pour les groupes
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                    }
            }
            
            // Nom
            VStack(alignment: .leading, spacing: 2) {
                Text(conversation.displayName(currentUserId: currentUserId))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if conversation.isGroup {
                    Text("\(conversation.memberCount) membres")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Error Banner
    
    @ViewBuilder
    private func errorBanner(message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
            Text(message)
                .font(.caption)
                .foregroundColor(.white)
            Spacer()
            Button("Réessayer") {
                errorMessage = nil
                loadMessages()
            }
            .font(.caption.weight(.semibold))
            .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.red.opacity(0.9))
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(), value: errorMessage)
    }
    
    // MARK: - Subviews
    
    /// Vue de scroll des messages
    private var messageScrollView: some View {
        ZStack {
            // Empty state visible même quand la ScrollView est masquée
            if messages.isEmpty && !isLoading {
                emptyMessagesView
            }
            
            ScrollViewReader { proxy in
                ScrollView {
                    messageContentView
                    
                    // Marqueur invisible pour l'ancrage en bas
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .opacity(hasScrolledToBottom || messages.isEmpty ? 1 : 0) // Toujours visible si vide
                .onChange(of: messages.count) { _, newCount in
                    guard newCount > 0 else { return }
                    if !hasScrolledToBottom {
                        // Premier chargement : laisser le LazyVStack se layouter avant de scroller
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 100_000_000)
                            if let lastId = messages.last?.id {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                            try? await Task.sleep(nanoseconds: 200_000_000)
                            if let lastId = messages.last?.id {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                            hasScrolledToBottom = true
                        }
                    } else {
                        // Nouveaux messages : scroll avec animation
                        withAnimation(.easeOut(duration: 0.3)) {
                            if let lastId = messages.last?.id {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Contenu des messages (loading, empty, ou liste)
    @ViewBuilder
    private var messageContentView: some View {
        if isLoading && messages.isEmpty {
            ProgressView()
                .padding()
        } else if !messages.isEmpty {
            messageListView
        }
    }
    
    /// État vide (aucun message)
    private var emptyMessagesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("Any messages")
                .foregroundColor(.gray)
            Text("Send the first message !")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    /// Liste des messages
    private var messageListView: some View {
        LazyVStack(spacing: 12) {
            ForEach(messages) { message in
                MessageBubble(
                    message: message,
                    showSenderName: true,
                    currentUserId: currentUserId
                )
                .id(message.id)
            }
        }
        .padding(.vertical)
    }
    
    // MARK: - Message Input Section
    
    /// Section de saisie de message en bas de l'écran
    private var messageInputSection: some View {
        HStack(spacing: 8) {
            // Bouton + à gauche (média/playlist)
            Menu {
                Button {
                    showPlaylistPicker = true
                } label: {
                    Label("Share Playlist", systemImage: "music.note.list")
                }
                Button {
                    showTrackPicker = true
                } label: {
                    Label("Share Track", systemImage: "music.note")
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.blue)
            }
            .padding(.leading, 4)
            .sheet(isPresented: $showPlaylistPicker) {
                PlaylistPickerForMessageView(
                    conversationId: conversation.id,
                    onPlaylistShared: {
                        showPlaylistPicker = false
                        loadMessages()
                    }
                )
            }
            .sheet(isPresented: $showTrackPicker) {
                TrackPickerForMessageView(
                    conversationId: conversation.id,
                    onTrackShared: {
                        showTrackPicker = false
                        loadMessages()
                    }
                )
            }

            // Champ de texte
            TextField("Message...", text: $newMessageText, axis: .vertical)
                .focused($isTextFieldFocused)
                .lineLimit(1...5)
                .padding(.vertical, 10)
            
            // Bouton d'envoi (n'apparaît que si du texte est saisi)
            if hasText {
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                }
                .padding(.trailing, 4)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(maxWidth: 340)
        .padding(.horizontal, 8)
        .background(Color(uiColor: .systemGray6))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hasText)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .padding(.bottom, 8)
        .background(Color(uiColor: .systemBackground))
    }
    
    /// Vérifie si le champ de texte contient du texte
    private var hasText: Bool {
        !newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Actions
    
    /// Marque la conversation comme lue (avec debouncing pour éviter trop d'appels)
    private func markConversationAsReadDebounced() {
        // Annule l'appel précédent s'il existe
        markAsReadTask?.cancel()

        // Crée un nouveau task avec délai
        markAsReadTask = Task {
            // Attend 1 seconde pour grouper les appels
            try? await Task.sleep(for: .seconds(1))

            // Si la tâche n'a pas été annulée, exécute le markAsRead
            guard !Task.isCancelled else { return }

            await markConversationAsRead()
        }
    }

    /// Charge les messages de la conversation depuis l'API
    private func loadMessages() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await ConversationAction.getConversationDetail(conversationId: conversation.id)
                await MainActor.run {
                    messages = response.value.messages
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Erreur lors du chargement: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func markConversationAsRead() async {
        do {
            _ = try await ConversationAction.markAsRead(id: conversation.id)
            print("✅ Conversation \(conversation.id) marquée comme lue")
        } catch {
            print("❌ Erreur lors du marquage comme lu: \(error.localizedDescription)")
        }
    }


    /// Envoie un nouveau message via l'API
    private func sendMessage() {
        let trimmedText = newMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedText.isEmpty else { return }
        
        // Créer un message temporaire pour l'affichage optimiste
        let now = ISO8601DateFormatter().string(from: Date())
        let tempMessage = Message(
            id: -1,
            author: CommonUser(
                id: currentUserId,
                username: userStore.user?.username ?? "Vous",
                profilePicture: userStore.user?.profilePicture
            ),
            type: "text",
            content: trimmedText,
            readAt: nil,
            conversationId: conversation.id,
            updatedAt: now,
            createdAt: now
        )
        
        messages.append(tempMessage)
        let messageToSend = trimmedText
        newMessageText = ""
        isTextFieldFocused = false
        
        Task {
            do {
                let response = try await MessageAction.sendTextMessage(
                    conversationId: conversation.id,
                    content: messageToSend
                )
                
                await MainActor.run {
                    // Remplacer le message temporaire par le vrai message de l'API
                    if let index = messages.firstIndex(where: { $0.id == -1 }) {
                        messages[index] = response.value
                    }
                }
            } catch {
                await MainActor.run {
                    // En cas d'erreur, retirer le message temporaire
                    messages.removeAll { $0.id == -1 }
                    errorMessage = "Erreur lors de l'envoi: \(error.localizedDescription)"
                    
                    // Remettre le texte dans le champ si l'envoi a échoué
                    newMessageText = messageToSend
                }
            }
        }
    }
}

// MARK: - Playlist Link Message View
/// Displays a playlist message. Content is the Apple Music URL.
/// Name and artwork are fetched from the MusicKit catalog at display time.
struct PlaylistLinkMessageView: View {
    let message: Message
    let isFromCurrentUser: Bool

    @State private var playlistName: String = "Playlist"
    @State private var artwork: Artwork? = nil

    /// The Apple Music URL — either the full content (new format) or extracted from legacy "🎵 Name\nURL"
    var linkURL: URL? {
        guard let content = message.content else { return nil }
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        // New format: content IS the URL
        if let url = URL(string: trimmed), url.scheme == "https" { return url }
        // Legacy format: URL embedded in text
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: content, range: NSRange(content.startIndex..., in: content))
        if let match = matches?.first, let range = Range(match.range, in: content) {
            return URL(string: String(content[range]))
        }
        return nil
    }

    /// Extracts a catalog playlist ID (pl.*) from the URL path.
    var catalogPlaylistID: String? {
        linkURL?.pathComponents.first(where: { $0.hasPrefix("pl.") })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                // Artwork via ArtworkImage — handles both https:// and musicKit:// schemes
                Group {
                    if let artwork {
                        ArtworkImage(artwork, width: 60, height: 60)
                    } else {
                        artworkPlaceholder
                    }
                }
                .frame(width: 60, height: 60)
                .cornerRadius(8)
                .clipped()

                VStack(alignment: .leading, spacing: 4) {
                    Text(playlistName)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(2)

                    HStack(spacing: 4) {
                        Image(systemName: "applelogo").font(.caption2)
                        Text("Apple Music").font(.caption)
                    }
                    .foregroundColor(.white.opacity(0.8))
                }

                Spacer(minLength: 0)
            }
            .padding(12)

            Divider().background(Color.white.opacity(0.2))

            if let url = linkURL {
                Link(destination: url) {
                    HStack {
                        Image(systemName: "play.circle.fill").font(.body)
                        Text(catalogPlaylistID != nil ? "Open in Apple Music" : "Search in Apple Music")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Image(systemName: "arrow.up.right").font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
            }
        }
        .background(
            LinearGradient(
                colors: [Color.pink.opacity(0.7), Color.pink.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .frame(maxWidth: 300)
        .task(id: message.id) { await loadPlaylistData() }
    }

    private var artworkPlaceholder: some View {
        Rectangle()
            .fill(Color.white.opacity(0.15))
            .overlay {
                Image(systemName: "music.note.list")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.6))
            }
    }

    // MARK: - MusicKit catalog fetch

    private func loadPlaylistData() async {
        guard let playlistID = catalogPlaylistID,
              MusicAuthorization.currentStatus == .authorized else { return }
        do {
            let request = MusicCatalogResourceRequest<Playlist>(
                matching: \.id, equalTo: MusicItemID(playlistID)
            )
            let response = try await request.response()
            guard let playlist = response.items.first else { return }
            playlistName = playlist.name
            artwork = playlist.artwork
        } catch {
            // MusicKit fetch failed — UI keeps default placeholder values
        }
    }
}

// MARK: - Backward Compatibility Extension
extension ChatDetailView {
    /// Initializer pour compatibilité avec l'ancien code (ChatsView)
    init(chatName: String) {
        // Créer une conversation temporaire pour la compatibilité
        let dummyAuthor = CommonUser(id: 0, username: chatName, profilePicture: nil)
        let dummyLastMessage = LightMessage(
            id: 0,
            preview: nil,
            author: dummyAuthor,
            createdAt: "2021-01-01T00:00:00Z",
            type: nil,
            content: nil
        )
        let participants = CommonUser(id: 0, username: chatName, profilePicture: nil)
        
        let config = ConversationConfig(id: 0)
        
        self.conversation = Conversation(
            config: config,
            type: "direct",
            lastMessage: dummyLastMessage,
            participants: [participants]
        )
    }
}

