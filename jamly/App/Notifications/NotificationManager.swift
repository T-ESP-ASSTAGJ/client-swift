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

final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var deviceToken: String?
    @Published var fcmToken: String?  // 🔥 Token Firebase
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var lastNotificationReceived: Date?
    @Published var lastNotificationPayload: [AnyHashable: Any]?
    @Published var notificationCount: Int = 0
    
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
        
        // Copie automatiquement dans le clipboard pour votre collègue
        UIPasteboard.general.string = tokenString
        
        // Optionnel : Envoyer au serveur
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
                "/users/device-token",
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
                "/users/device-token",
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
    
        
        // Traiter les données de la notification
        handleNotificationData(userInfo)
    }
    
    /// Appelé quand l'utilisateur tape sur une notification
    @MainActor
    func didTapNotification(_ userInfo: [AnyHashable: Any]) {
        
        // Traiter l'action de la notification
        handleNotificationData(userInfo)
        
        // TODO: Navigation vers le contenu approprié
        // Par exemple, si c'est un nouveau post, ouvrir le post
        if let postId = userInfo["post_id"] as? String {
            // Ici vous pouvez publier une notification pour naviguer
            // ou utiliser un deep link handler
        }
    }
    
    /// Traite les données d'une notification
    private func handleNotificationData(_ userInfo: [AnyHashable: Any]) {
        // Extraire les informations communes
        if let aps = userInfo["aps"] as? [String: Any] {
            if let alert = aps["alert"] as? [String: Any] {
                let title = alert["title"] as? String ?? ""
                let body = alert["body"] as? String ?? ""
            }
        }
        
        // Extraire les données custom
        if let type = userInfo["type"] as? String {
            print("🏷️ Type: \(type)")
            
            switch type {
            case "new_like":
                print("❤️ Nouveau like reçu")
            case "new_comment":
                print("💬 Nouveau commentaire")
            case "new_follower":
                print("👤 Nouveau follower")
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
