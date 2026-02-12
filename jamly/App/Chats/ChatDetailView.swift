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
    @State private var currentUserId: Int = 1 // TODO: Récupérer depuis UserDefaults ou AuthManager
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Zone de messages avec défilement
            ScrollViewReader { proxy in
                ScrollView {
                    if isLoading && messages.isEmpty {
                        ProgressView()
                            .padding()
                    } else if messages.isEmpty {
                        // État vide
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
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                MessageBubble(
                                    message: message,
                                    showSenderName: conversation.isGroup,
                                    currentUserId: currentUserId
                                )
                                .id(message.id)
                            }
                        }
                        .padding(.vertical)
                    }
                }
                .onChange(of: messages.count) { oldValue, newValue in
                    // Scroll automatique vers le dernier message
                    if let lastMessage = messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            messageInputSection
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .navigationTitle("Test")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if conversation.isGroup {
                    Button {
                        // TODO: Action pour voir les infos du groupe
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
        }
        .onAppear {
            loadMessages()
        }
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
    
    /// Charge les messages de la conversation depuis l'API
    private func loadMessages() {
        isLoading = true
        
        // TODO: Remplacer par un vrai appel API
        // Exemple:
        // Task {
        //     do {
        //         messages = try await APIManager.shared.getMessages(conversationId: conversation.id)
        //         isLoading = false
        //     } catch {
        //         print("Erreur: \(error)")
        //         isLoading = false
        //     }
        // }
        
        // Messages de test pour l'instant
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            messages = [
                Message(
                    id: 1,
                    author: Author(
                        id: 2,
                        username: conversation.displayName,
                        profilePicture: conversation.profilePicture
                    ),
                    type: "text",
                    content: "Salut ! Comment ça va ?",
                    trackMetaData: nil,
                    memberCount: 2,
                    isRead: true,
                    readAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3600)),
                    conversationId: conversation.id
                ),
                Message(
                    id: 2,
                    author: Author(id: currentUserId, username: "Moi", profilePicture: nil),
                    type: "text",
                    content: "Ça va bien ! Tu as écouté ce son ?",
                    trackMetaData: nil,
                    memberCount: 2,
                    isRead: true,
                    readAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3500)),
                    conversationId: conversation.id
                ),
                Message(
                    id: 3,
                    author: Author(id: currentUserId, username: "Moi", profilePicture: nil),
                    type: "track",
                    content: "Blinding Lights - The Weeknd",
                    trackMetaData: ["Blinding Lights", "The Weeknd", "https://example.com/cover.jpg"],
                    memberCount: 2,
                    isRead: false,
                    readAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3400)),
                    conversationId: conversation.id
                )
            ]
            isLoading = false
        }
    }
    
    /// Envoie un nouveau message via l'API
    private func sendMessage() {
        let trimmedText = newMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedText.isEmpty else { return }
        
        isLoading = true
        
        // TODO: Remplacer par un vrai appel API
        // Exemple:
        // let request = SendMessageRequest(conversationId: conversation.id, content: trimmedText)
        // Task {
        //     do {
        //         let newMessage = try await APIManager.shared.sendMessage(request)
        //         messages.append(newMessage)
        //         newMessageText = ""
        //         isLoading = false
        //     } catch {
        //         print("Erreur: \(error)")
        //         isLoading = false
        //     }
        // }
        
        // Simulation pour l'instant
        let newMessage = Message(
            id: messages.count + 1,
            author: Author(id: currentUserId, username: "Moi", profilePicture: nil),
            type: "text",
            content: trimmedText,
            trackMetaData: nil,
            memberCount: conversation.memberCount,
            isRead: false,
            readAt: ISO8601DateFormatter().string(from: Date()),
            conversationId: conversation.id
        )
        
        messages.append(newMessage)
        newMessageText = ""
        isLoading = false
    }
}
// MARK: - Backward Compatibility Extension
extension ChatDetailView {
    /// Initializer pour compatibilité avec l'ancien code (ChatsView)
    init(chatName: String) {
        // Créer une conversation temporaire pour la compatibilité
        self.conversation = Conversation(
            id: 0,
            isGroup: false,
            groupName: nil,
            unreadCount: 0,
            memberCount: 2,
            type: "direct",
            lastMessage: [],
            participantsInfo: [[chatName, ""]]
        )
    }
}

