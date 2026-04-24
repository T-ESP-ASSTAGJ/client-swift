//
//  NotificationManager.swift
//  jamly
//
//  Created by Jonathan Dumesnil on 20/03/2026.
//

import Foundation
import UserNotifications
import UIKit
import Combine

// MARK: - Notification Names
extension Notification.Name {
    static let navigateToProfile = Notification.Name("navigateToProfile")
    static let navigateToConversation = Notification.Name("navigateToConversation")
}

struct NotificationManagerEndpoint {
    static var deviceToken: String { "\(UserEndpoints.users)/device-token" }
}

final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var deviceToken: String?
    @Published var fcmToken: String?  // 🔥 Token Firebase
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var lastNotificationReceived: Date?
    @Published var lastNotificationPayload: [AnyHashable: Any]?
    @Published var notificationCount: Int = 0
    @Published var pendingPostId: Int?
    @Published var pendingHighlightedCommentId: Int?
    @Published var pendingProfileUserId: Int?
    @Published var pendingConversationId: Int?
    
    private init() {
        // Initialisation privée pour singleton
    }
    
    /// Demande l'autorisation et enregistre l'appareil pour les notifications push
    @MainActor
    func requestAuthorization() async {
        do {
            let center = UNUserNotificationCenter.current()
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            
            if granted {
                print("✅ Autorisation notifications accordée")
                await registerForRemoteNotifications()
            } else {
                print("❌ Autorisation notifications refusée")
            }
            
            // Met à jour le statut
            let settings = await center.notificationSettings()
            self.authorizationStatus = settings.authorizationStatus
            
        } catch {
            print("❌ Erreur lors de la demande d'autorisation: \(error)")
        }
    }
    
    /// Enregistre l'appareil pour recevoir des notifications push
    @MainActor
    func registerForRemoteNotifications() async {
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    /// Appelé quand le device token est reçu
    @MainActor
    func didReceiveDeviceToken(_ deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = tokenString
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📱 DEVICE TOKEN REÇU")
        print("   Token: \(tokenString)")
        print("   Copié dans le clipboard ✓")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // Copie automatiquement dans le clipboard
        UIPasteboard.general.string = tokenString
        
        // Envoyer au serveur
        Task {
            await sendTokenToServer(tokenString)
        }
    }
    
    /// Appelé en cas d'erreur d'enregistrement
    @MainActor
    func didFailToRegisterForRemoteNotifications(with error: Error) {
        print("❌ Échec d'enregistrement APNs: \(error.localizedDescription)")
    }
    
    /// Envoie le token au serveur backend
    private func sendTokenToServer(_ token: String) async {
        do {
            try await APIClient.shared.request(
                NotificationManagerEndpoint.deviceToken,
                method: .post,
                body: ["deviceToken": token],
                responseType: EmptyResponse.self
            )
            print("✅ Device token envoyé au serveur")
        } catch {
            print("⚠️ Impossible d'envoyer le token au serveur: \(error)")
        }
    }
    
    /// Envoie le device token manuellement (peut être appelé après connexion)
    @MainActor
    func sendDeviceTokenToServer() async {
        guard let token = deviceToken else {
            print("⚠️ Pas de device token disponible")
            return
        }
        
        await sendTokenToServer(token)
    }
    
    /// Appelé quand le FCM token Firebase est reçu
    @MainActor
    func didReceiveFCMToken(_ token: String) {
        self.fcmToken = token
        
        // Copie automatiquement dans le clipboard pour votre collègue
        UIPasteboard.general.string = token
        
        // Envoyer le FCM token au serveur
        Task {
            await sendFCMTokenToServer(token)
        }
    }
    
    /// Envoie le FCM token au serveur backend
    private func sendFCMTokenToServer(_ token: String) async {
        do {
            try await APIClient.shared.request(
                NotificationManagerEndpoint.deviceToken,
                method: .post,
                body: ["deviceToken": token],
                responseType: EmptyResponse.self
            )
            print("✅ FCM Token envoyé au serveur")
        } catch {
            print("⚠️ Impossible d'envoyer le FCM token au serveur: \(error)")
        }
    }
    
    /// Vérifie le statut actuel des notifications
    @MainActor
    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        self.authorizationStatus = settings.authorizationStatus
    }
    
    // MARK: - Gestion des notifications reçues
    
    /// Appelé quand une notification est reçue (premier plan ou arrière-plan)
    @MainActor
    func didReceiveNotification(_ userInfo: [AnyHashable: Any]) {
        notificationCount += 1
        lastNotificationReceived = Date()
        lastNotificationPayload = userInfo
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔔 NOTIFICATION REÇUE #\(notificationCount)")
        print("   Timestamp: \(Date())")
        print("   Payload complet:")
        print(userInfo)
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // Traiter les données de la notification
        handleNotificationData(userInfo)
    }
    
    /// Appelé quand l'utilisateur tape sur une notification
    @MainActor
    func didTapNotification(_ userInfo: [AnyHashable: Any]) {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("👆 NOTIFICATION TAPÉE")
        print("   Timestamp: \(Date())")
        print("   Payload complet:")
        print(userInfo)
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // Traiter l'action de la notification
        handleNotificationData(userInfo)
        
        // Navigation selon entityClass / userId
        let entityClass = userInfo["entityClass"] as? String
        let entityId = Self.intFromAny(userInfo["entityId"])
        let postId = Self.intFromAny(userInfo["postId"])
        let userId = Self.intFromAny(userInfo["userId"])
        let conversationId = Self.intFromAny(userInfo["conversationId"])
        print("📍 Tentative navigation:")
        print("   entityClass: \(entityClass ?? "nil")")
        print("   entityId: \(entityId.map(String.init) ?? "nil")")
        print("   postId: \(postId.map(String.init) ?? "nil")")
        print("   userId: \(userId.map(String.init) ?? "nil")")
        print("   conversationId: \(conversationId.map(String.init) ?? "nil")")

        if let entityClass {
            if entityClass.contains("Comment") {
                guard let postId, let entityId else {
                    print("❌ postId ou entityId manquant pour Comment")
                    return
                }
                pendingHighlightedCommentId = entityId
                pendingPostId = postId
                print("✅ Navigation vers post \(postId) avec commentaire \(entityId) en tête")
                return
            }
            if entityClass.contains("Post") {
                guard let entityId else {
                    print("❌ entityId manquant pour Post")
                    return
                }
                pendingHighlightedCommentId = nil
                pendingPostId = entityId
                print("✅ Navigation vers le post \(entityId) demandée")
                return
            }
            if entityClass.contains("Message") || entityClass.contains("Conversation") {
                let target = conversationId ?? entityId
                guard let target else {
                    print("❌ conversationId/entityId manquant pour Message/Conversation")
                    return
                }
                pendingConversationId = target
                print("✅ Navigation vers conversation \(target) demandée")
                return
            }
            if entityClass.contains("User") || entityClass.contains("Follow") {
                let target = entityId ?? userId
                guard let target else {
                    print("❌ userId/entityId manquant pour User/Follow")
                    return
                }
                pendingProfileUserId = target
                print("✅ Navigation vers profil user \(target) demandée")
                return
            }
            print("ℹ️ entityClass non géré pour navigation: \(entityClass)")
            return
        }

        // Pas d'entityClass : fallbacks sur les ids présents
        if let conversationId {
            pendingConversationId = conversationId
            print("✅ Navigation vers conversation \(conversationId) demandée (fallback)")
            return
        }
        if let userId {
            pendingProfileUserId = userId
            print("✅ Navigation vers profil user \(userId) demandée (follow)")
            return
        }

        print("❌ Rien à faire : aucun id exploitable")
    }

    private static func intFromAny(_ value: Any?) -> Int? {
        if let int = value as? Int { return int }
        if let str = value as? String { return Int(str) }
        if let num = value as? NSNumber { return num.intValue }
        return nil
    }
    
    /// Traite les données d'une notification
    private func handleNotificationData(_ userInfo: [AnyHashable: Any]) {
        // Extraire les informations communes
        if let aps = userInfo["aps"] as? [String: Any] {
            print("📦 APS Data:")
            
            if let alert = aps["alert"] as? [String: Any] {
                let title = alert["title"] as? String ?? ""
                let body = alert["body"] as? String ?? ""
                print("   Title: \(title)")
                print("   Body: \(body)")
            } else if let alertString = aps["alert"] as? String {
                print("   Alert: \(alertString)")
            }
            
            if let badge = aps["badge"] as? Int {
                print("   Badge: \(badge)")
            }
            
            if let sound = aps["sound"] {
                print("   Sound: \(sound)")
            }
        }
        
        // ✅ Vérifier si une profilePicture est présente
        if let profilePicture = userInfo["profilePicture"] as? String {
            print("🖼️ Profile Picture URL: \(profilePicture)")
        }
        
        // Extraire les données custom
        print("📝 Custom Data:")
        for (key, value) in userInfo where key as? String != "aps" {
            print("   \(key): \(value)")
        }
        
        if let type = userInfo["type"] as? String {
            print("🏷️ Type de notification: \(type)")
            
            switch type {
            case "like", "new_like":
                print("❤️ Nouveau like reçu")
                if let entityId = userInfo["entityId"] as? String {
                    print("   Entity ID: \(entityId)")
                }
                if let entityClass = userInfo["entityClass"] as? String {
                    print("   Entity Class: \(entityClass)")
                }
            case "comment", "new_comment":
                print("💬 Nouveau commentaire")
                if let entityId = userInfo["entityId"] as? String {
                    print("   Entity ID: \(entityId)")
                }
            case "follow", "new_follower":
                print("👤 Nouveau follower")
                if let userId = userInfo["userId"] as? String {
                    print("   User ID: \(userId)")
                }
            case "message", "new_message":
                print("💌 Nouveau message")
                if let conversationId = userInfo["conversationId"] as? String {
                    print("   Conversation ID: \(conversationId)")
                }
            default:
                print("ℹ️ Type inconnu: \(type)")
            }
        }
    }
    
    // MARK: - Actions de test
    
    /// Envoie une notification de test locale
    @MainActor
    func sendTestNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "Ceci est une notification de test envoyée localement"
        content.sound = .default
        content.badge = NSNumber(value: notificationCount + 1)
        
        // Déclencher dans 2 secondes
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Notification de test programmée pour dans 2 secondes")
        } catch {
            print("❌ Erreur lors de l'envoi de la notification de test: \(error)")
        }
    }
    
    /// Réinitialise le badge de l'app
    @MainActor
    func resetBadge() async {
        UIApplication.shared.applicationIconBadgeNumber = 0
        print("✅ Badge réinitialisé")
    }
}
