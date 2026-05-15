//
//  ChatsViewModel.swift
//  jamly
//
//  Created by Jonathan Dumesnil on 12/02/2026.
//

import Combine
import SwiftUI

/// ViewModel de l'inbox (liste des conversations).
///
/// Gère le chargement initial, la pagination, la recherche locale, la suppression et la
/// mise à jour du statut lu/non-lu. Réagit également aux notifications push entrantes pour
/// mettre à jour le compteur de messages non-lus sans recharger la liste complète.
@MainActor
class ChatsViewModel: ObservableObject {
    // MARK: - Published Properties

    /// Toutes les conversations connues, dans l'ordre du serveur.
    @Published var conversations: [Conversation] = []
    /// Vue filtrée affichée à l'écran, dérivée de ``searchText``.
    @Published var filteredConversations: [Conversation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    /// Texte de recherche saisi par l'utilisateur. Recalcule ``filteredConversations`` à chaque
    /// changement via le `didSet`.
    @Published var searchText = "" {
        didSet {
            filterConversations()
        }
    }
    @Published var isLoadingMore = false

    private var currentPage = 1
    private var hasMorePages = true
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    /// S'abonne aux notifications de nouveaux messages reçus pour incrémenter le compteur
    /// non-lu sans rafraîchir l'inbox complet.
    init() {
        NotificationCenter.default.publisher(for: .messageNotificationReceived)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] note in
                guard let conversationId = note.userInfo?["conversationId"] as? Int else { return }
                self?.handleIncomingMessageNotification(conversationId: conversationId)
            }
            .store(in: &cancellables)
    }

    /// Incrémente le compteur non-lu d'une conversation suite à la réception d'un push.
    ///
    /// Si la conversation n'est pas encore présente dans l'inbox (premier message d'un
    /// nouveau chat), l'inbox complet est rechargé pour la faire apparaître.
    ///
    /// - Parameter conversationId: Identifiant de la conversation impactée.
    private func handleIncomingMessageNotification(conversationId: Int) {
        guard let index = conversations.firstIndex(where: { $0.id == conversationId }) else {
            // Conversation pas encore dans la liste (nouveau chat) → recharger
            Task { await loadConversations() }
            return
        }
        let current = conversations[index]
        let newConfig = ConversationConfig(
            id: current.id,
            isGroup: current.isGroup,
            groupName: current.groupName ?? "",
            unreadCount: current.unreadCount + 1,
            memberCount: current.memberCount
        )
        let updated = Conversation(
            config: newConfig,
            type: current.type,
            lastMessage: current.lastMessage,
            participants: current.participants
        )
        withAnimation {
            conversations[index] = updated
            filterConversations()
        }
    }
    
    // MARK: - Public Methods

    /// Charge la première page de conversations depuis l'API et remplace l'état courant.
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
    
    /// Charge la page suivante de conversations (infinite scroll).
    ///
    /// Déduplique sur l'identifiant pour éviter qu'une conversation déjà chargée n'apparaisse
    /// deux fois. Si la réponse renvoie moins de 20 éléments, considère qu'il n'y a plus de
    /// page à charger.
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
    
    /// Indique si une conversation donnée doit déclencher le chargement de la page suivante.
    ///
    /// La règle est : « si on est sur l'avant-avant-dernière conversation, on précharge la suite »,
    /// ce qui permet une infinite scroll fluide.
    ///
    /// - Parameter conversation: Conversation actuellement visible à l'écran.
    /// - Returns: `true` si le seuil de prefetch est atteint.
    func shouldLoadMore(for conversation: Conversation) -> Bool {
        // Charger plus quand on atteint les 3 dernières conversations
        guard let lastConversation = filteredConversations.suffix(3).first else {
            return false
        }
        return conversation.id == lastConversation.id
    }

    /// Rafraîchit l'inbox via un pull-to-refresh.
    func refresh() async {
        await loadConversations()
    }

    /// Variante de pagination prenant explicitement la page courante.
    ///
    /// Conservée pour les appelants qui maintiennent eux-mêmes la page (legacy) ;
    /// préférer ``loadMoreConversations()`` pour les nouveaux usages.
    ///
    /// - Parameter currentPage: Page actuelle avant l'appel ; la suivante sera chargée.
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
    
    /// Supprime une conversation côté serveur et la retire de l'inbox local avec animation.
    ///
    /// - Parameter conversation: Conversation à supprimer.
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

    /// Marque une conversation comme lue côté serveur et remet `unreadCount` à zéro localement.
    ///
    /// - Parameter conversation: Conversation à marquer comme lue.
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

    /// Recalcule ``filteredConversations`` en fonction de ``searchText``.
    ///
    /// Filtre sur le nom du groupe et l'aperçu du dernier message ; insensible à la casse
    /// via `localizedCaseInsensitiveContains`.
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
