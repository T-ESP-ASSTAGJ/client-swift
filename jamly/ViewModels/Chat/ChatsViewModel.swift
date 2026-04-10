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
    @Published var isLoadingMore = false
    
    private var currentPage = 1
    private var hasMorePages = true
    
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
    
    func loadMoreConversations() async {
        // Ne pas charger si déjà en cours ou si plus de pages disponibles
        guard !isLoading, !isLoadingMore, hasMorePages else { return }
        
        isLoadingMore = true
        
        do {
            let nextPage = currentPage + 1
            let response = try await ConversationAction.getConversations(page: nextPage)
            let newConversations = response.value
            
            // Éviter les doublons
            let existingIds = Set(conversations.map { $0.id })
            let uniqueNew = newConversations.filter { !existingIds.contains($0.id) }
            
            if !uniqueNew.isEmpty {
                conversations.append(contentsOf: uniqueNew)
                filterConversations()
                currentPage = nextPage
                
                // Vérifier s'il y a potentiellement d'autres pages
                hasMorePages = newConversations.count >= 20
                
                print("✅ Loaded \(uniqueNew.count) more conversations (page \(nextPage))")
            } else {
                hasMorePages = false
                print("ℹ️ No more conversations to load")
            }
        } catch {
            print("❌ Error loading more conversations: \(error)")
        }
        
        isLoadingMore = false
    }
    
    func shouldLoadMore(for conversation: Conversation) -> Bool {
        // Charger plus quand on atteint les 3 dernières conversations
        guard let lastConversation = filteredConversations.suffix(3).first else {
            return false
        }
        return conversation.id == lastConversation.id
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
        do {
            // Appel API pour marquer comme lu
            _ = try await ConversationAction.markAsRead(id: conversation.id)

            // Mettre à jour localement le unreadCount
            withAnimation {
                if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
                    // Créer une nouvelle configuration avec unreadCount à 0
                    let config = ConversationConfig(
                        id: conversation.id
                    )

                    // Créer une nouvelle conversation avec unreadCount à 0
                    let updatedConversation = Conversation(
                        config: config,
                        type: conversation.type,
                        lastMessage: conversation.lastMessage,
                        participants: conversation.participants
                    )

                    conversations[index] = updatedConversation
                    filterConversations()
                }
            }

            print("✅ Conversation \(conversation.id) marked as read")
        } catch {
            errorMessage = "Impossible de marquer la conversation comme lue"
            print("❌ Error marking conversation as read: \(error)")
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
                let nameMatch = conversation.groupName?.localizedCaseInsensitiveContains(searchText)
                
                // Recherche dans le dernier message
                let messageMatch = conversation.lastMessage?.preview?
                    .localizedCaseInsensitiveContains(searchText)
                
                return nameMatch! || (messageMatch != nil)
            }
        }
    }
}
