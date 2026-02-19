//
//  ChatsViewModel.swift
//  jamly
//
//  Created by Jonathan Dumesnil on 12/02/2026.
//

import Combine
import SwiftUI

@MainActor
class ChatsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var conversations: [Conversation] = []
    @Published var filteredConversations: [Conversation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = "" {
        didSet {
            filterConversations()
        }
    }
    
    // MARK: - Lifecycle
    
    init() {
        // Initialisation si nécessaire
    }
    
    // MARK: - Public Methods
    
    /// Charger les conversations depuis l'API
    func loadConversations() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await ConversationAction.getConversations()
            conversations = response.value
            filterConversations()
            print("✅ Loaded \(conversations.count) conversations")
        } catch {
            errorMessage = "Impossible de charger les conversations"
            print("❌ Error loading conversations: \(error)")
        }
        
        isLoading = false
    }
    
    /// Rafraîchir les conversations (pull-to-refresh)
    func refresh() async {
        await loadConversations()
    }
    
    /// Charger plus de conversations (pagination)
    func loadMoreConversations(currentPage: Int) async {
        guard !isLoading else { return }
        
        do {
            let response = try await ConversationAction.getConversations(page: currentPage + 1)
            let newConversations = response.value
            
            // Éviter les doublons
            _ = Set(newConversations.map { $0.id })
            let existingIds = Set(conversations.map { $0.id })
            let uniqueNew = newConversations.filter { !existingIds.contains($0.id) }
            
            conversations.append(contentsOf: uniqueNew)
            filterConversations()
            
            print("✅ Loaded \(uniqueNew.count) more conversations")
        } catch {
            print("❌ Error loading more conversations: \(error)")
        }
    }
    
    /// Supprimer une conversation
    func deleteConversation(_ conversation: Conversation) async {
        do {
            _ = try await ConversationAction.deleteConversation(id: conversation.id)
            
            withAnimation {
                conversations.removeAll { $0.id == conversation.id }
                filterConversations()
            }
            
            print("✅ Conversation \(conversation.id) deleted successfully")
        } catch {
            errorMessage = "Impossible de supprimer la conversation"
            print("❌ Error deleting conversation: \(error)")
        }
    }
    
    /// Basculer le statut lu/non lu d'une conversation
    func toggleReadStatus(_ conversation: Conversation) async {
        let shouldMarkAsRead = conversation.unreadCount > 0
        
        do {
            let response = try await ConversationAction.markAsRead(id: conversation.id, isRead: shouldMarkAsRead)
            
            // Mettre à jour la conversation localement avec la réponse de l'API
            if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
                withAnimation {
                    conversations[index] = response.value
                    filterConversations()
                }
            }
            
            print("✅ Conversation \(conversation.id) marked as \(shouldMarkAsRead ? "read" : "unread")")
        } catch {
            errorMessage = "Impossible de modifier le statut"
            print("❌ Error toggling read status: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    /// Filtrer les conversations selon le texte de recherche
    private func filterConversations() {
        if searchText.isEmpty {
            filteredConversations = conversations
        } else {
            filteredConversations = conversations.filter { conversation in
                // Recherche dans le nom
                let nameMatch = conversation.groupName.localizedCaseInsensitiveContains(searchText)
                
                // Recherche dans le dernier message
                let messageMatch = conversation.lastMessage?.preview
                    .localizedCaseInsensitiveContains(searchText)
                
                return nameMatch || (messageMatch != nil)
            }
        }
    }
}
