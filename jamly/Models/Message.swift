//
//  Message.swift
//  jamly
//
//  Created by Jonathan Dumesnil on 06/02/2026.
//

import Foundation

// MARK: - Message

/// Message individuel échangé dans une conversation.
///
/// Le champ `type` distingue les messages texte (`"text"`), morceaux Apple Music partagés
/// (`"track"`, `"music"`) et autres partages génériques (`"share"`). Certains champs
/// (`readAt`, `conversationId`, `updatedAt`) sont optionnels car ils ne sont renvoyés
/// que sur certains endpoints.
struct Message: Codable, Identifiable, Hashable {
    let id: Int
    let author: CommonUser
    let type: String
    let content: String?

    // Champs qui peuvent varier selon l'endpoint
    let readAt: String?
    let conversationId: Int?
    let updatedAt: String?

    let createdAt: String

    // MARK: - Computed Properties

    /// Indique si le message porte un contenu musical (morceau partagé).
    ///
    /// Couvre deux cas :
    /// - `type` vaut `"track"` ou `"music"` (cas standard) ;
    /// - `type` vaut `"share"` et `content` est une URL Apple Music de morceau
    ///   (les playlists sont exclues car traitées séparément).
    var isMusicMessage: Bool {
        if type == "track" || type == "music" { return true }
        if type == "share", let content = content,
           content.contains(Config.appleMusicHost), !content.contains(Config.appleMusicPlaylistPath) { return true }
        return false
    }

    /// `true` si le destinataire a lu le message (présence d'un `readAt`).
    var isRead: Bool {
        readAt != nil
    }

    /// Date de création parsée depuis le champ ISO8601 `createdAt`.
    ///
    /// En cas d'échec de parsing, retourne `Date()` pour éviter un crash en UI.
    var createdDate: Date {
        ISO8601DateFormatter().date(from: createdAt) ?? Date()
    }

    /// Heure du message au format `HH:mm`, utilisée pour les bulles de chat.
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: createdDate)
    }

    /// Date longue localisée en français (ex. `"7 mai à 14:32"`), utilisée pour les séparateurs.
    var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "d MMM 'à' HH:mm"
        return formatter.string(from: createdDate)
    }

    /// Indique si l'auteur du message est l'utilisateur connecté.
    ///
    /// Utilisé pour aligner la bulle à droite ou à gauche dans la vue de chat.
    /// - Parameter currentUserId: Identifiant de l'utilisateur connecté.
    func isFromCurrentUser(currentUserId: Int) -> Bool {
        author.id == currentUserId
    }
}

// MARK: - Light Message (pour la liste des conversations)

/// Version allégée d'un message utilisée comme aperçu dans la liste des conversations.
///
/// Le serveur peut renvoyer un `preview` pré-calculé. À défaut, ``displayPreview`` reconstruit
/// un aperçu côté client à partir du type et du contenu.
struct LightMessage: Codable, Identifiable, Hashable {
    let id: Int
    let preview: String?
    let author: CommonUser
    let createdAt: String
    let type: String?
    let content: String?

    /// Aperçu à afficher dans la cellule de conversation.
    ///
    /// Ordre de priorité :
    /// 1. `preview` si fourni par l'API,
    /// 2. Une mention « 🎵 Contenu partagé » pour les messages musicaux,
    /// 3. Le `content` brut,
    /// 4. Un fallback générique `"Message"`.
    var displayPreview: String {
        if let preview = preview {
            return preview
        }

        if let type = type, type == "track" || type == "music" || type == "share" {
            return "🎵 Contenu partagé"
        }

        if let content = content {
            return content
        }

        return "Message"
    }
}

/// Enveloppe utilisée pour les messages diffusés via Mercure (Server-Sent Events).
///
/// Le champ `type` permet à ``MercureService`` de router le payload vers la bonne
/// destination (nouveau message, mise à jour, etc.) avant décodage du ``Message``.
struct MercureMessageWrapper: Codable {
    let type: String
    let message: Message
}
