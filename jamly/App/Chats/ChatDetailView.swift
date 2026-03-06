//
//  ChatDetailView.swift
//  jamly
//
//  Created by REVERSS on 31/12/2025.
//

import SwiftUI

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
                    
                    if isFromCurrentUser {
                        Image(systemName: message.isRead ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.caption2)
                            .foregroundColor(message.isRead ? .blue : .gray)
                    }
                }
                .padding(.horizontal, 4)
            }
            
            if !isFromCurrentUser {
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Music Message View
/// Vue spéciale pour les messages contenant une piste musicale
struct MusicMessageView: View {
    let message: Message
    
    var body: some View {
        HStack(spacing: 12) {
            // Image de la piste
            if let imageUrl = message.trackImageUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay {
                            Image(systemName: "music.note")
                                .foregroundColor(.white)
                        }
                }
                .frame(width: 50, height: 50)
                .cornerRadius(8)
            }
            
            // Infos de la piste
            VStack(alignment: .leading, spacing: 4) {
                if let title = message.trackTitle {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                if let artist = message.trackArtist {
                    Text(artist)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "music.note")
                        .font(.caption2)
                    Text("Piste partagée")
                        .font(.caption2)
                }
                .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            // Bouton play
            Button {
                // TODO: Jouer la piste
            } label: {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
        .padding(12)
        .background(Color.blue.opacity(0.8))
        .cornerRadius(16)
        .frame(maxWidth: 280)
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
    @FocusState private var isTextFieldFocused: Bool
    
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
            setupMercure()
        }
        .onDisappear {
            mercureService.unsubscribe()
        }
    }
    
    // MARK: - Mercure Setup
    
    /// Configure Mercure pour recevoir les messages en temps réel
    private func setupMercure() {
        let topic = "/conversations/\(conversation.id)"
        
        mercureService.subscribe(topics: [topic]) { receivedTopic, data in
            handleMercureMessage(data: data)
        }
    }
    
    /// Traite un message reçu via Mercure
    private func handleMercureMessage(data: Data) {
        do {
            let decoder = JSONDecoder()
            
            // Votre backend envoie un wrapper avec "type" et "message"
            let wrapper = try decoder.decode(MercureMessageWrapper.self, from: data)
            let newMessage = wrapper.message
            
            print("✅ Message Mercure parsé: \(newMessage.content ?? "no content")")
            print("   Message ID: \(newMessage.id)")
            print("   Auteur: \(newMessage.author.username)")
            
            // Vérifier si c'est notre propre message (déjà affiché en optimiste)
            if newMessage.isFromCurrentUser(currentUserId: currentUserId) {
                // C'est notre message : remplacer le message temporaire (ID -1)
                if let tempIndex = messages.firstIndex(where: { $0.id == -1 }) {
                    messages[tempIndex] = newMessage
                    print("✅ Message temporaire remplacé par le message réel")
                } else if !messages.contains(where: { $0.id == newMessage.id }) {
                    // Le message temporaire a déjà été remplacé, mais pas par Mercure
                    messages.append(newMessage)
                    print("✅ Message ajouté (envoyé par nous)")
                } else {
                    print("⚠️ Message déjà présent (ignoré)")
                }
            } else {
                // Message d'un autre utilisateur : l'ajouter s'il n'existe pas
                if !messages.contains(where: { $0.id == newMessage.id }) {
                    messages.append(newMessage)
                    print("✅ Message ajouté (reçu d'un autre utilisateur)")
                } else {
                    print("⚠️ Message déjà présent (ignoré)")
                }
            }
        } catch {
            print("❌ Erreur parsing message Mercure: \(error)")
            
            // Debug : afficher le JSON brut
            if let jsonString = String(data: data, encoding: .utf8) {
                print("   JSON reçu: \(jsonString)")
            }
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
        ScrollViewReader { proxy in
            ScrollView {
                messageContentView
            }
            .onChange(of: messages.count) { _ in
                scrollToBottom(proxy: proxy)
            }
        }
    }
    
    /// Contenu des messages (loading, empty, ou liste)
    @ViewBuilder
    private var messageContentView: some View {
        if isLoading && messages.isEmpty {
            ProgressView()
                .padding()
        } else if messages.isEmpty {
            emptyMessagesView
        } else {
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
            // Bouton média à gauche (dans l'input)
            Button {
                // TODO: Ouvrir le sélecteur de musique
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.blue)
            }
            .padding(.leading, 4)
            
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
    
    /// Scroll vers le dernier message
    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let lastMessage = messages.last else { return }
        withAnimation {
            proxy.scrollTo(lastMessage.id, anchor: .bottom)
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
                    print("❌ Error loading messages: \(error)")
                }
            }
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
            track: nil,
            trackMetadata: nil,
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
                    print("❌ Error sending message: \(error)")
                    
                    // Remettre le texte dans le champ si l'envoi a échoué
                    newMessageText = messageToSend
                }
            }
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
        
        self.conversation = Conversation(
            id: 0,
            groupName: "Test",
            unreadCount: 0,
            memberCount: 2,
            type: "direct",
            lastMessage: dummyLastMessage,
            participants: [participants]
        )
    }
}

