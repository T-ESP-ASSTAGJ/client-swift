//
//  AppDelegate.swift
//  jamly
//
//  Created by Jonathan Dumesnil on 20/03/2026.
//

import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        
        FirebaseApp.configure()
        
        UNUserNotificationCenter.current().delegate = self
        
        Messaging.messaging().delegate = self
        
        return true
    }
    
    // ✅ Appelé quand le device token APNs est reçu
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Envoie le token APNs à Firebase
        Messaging.messaging().apnsToken = deviceToken
        
        // 📱 Debug: Affiche le device token (NE PAS utiliser pour Firebase Console)
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        _ = tokenParts.joined()
        
        Task { @MainActor in
            NotificationManager.shared.didReceiveDeviceToken(deviceToken)
        }
    }
    
    // ❌ Appelé en cas d'erreur
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Task { @MainActor in
            NotificationManager.shared.didFailToRegisterForRemoteNotifications(with: error)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // Notification reçue quand l'app est au premier plan
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("📬 ✅ Notification reçue (app au premier plan)")
        
        let userInfo = notification.request.content.userInfo
        _ = notification.request.content
        
        Task { @MainActor in
            NotificationManager.shared.didReceiveNotification(userInfo)
        }
        
        // Affiche la notification même si l'app est ouverte
        completionHandler([.banner, .sound, .badge])
    }
    
    // L'utilisateur a tapé sur une notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("👆 ✅ Utilisateur a tapé sur la notification")
        
        let userInfo = response.notification.request.content.userInfo
        _ = response.notification.request.content
        
        Task { @MainActor in
            NotificationManager.shared.didTapNotification(userInfo)
        }
        
        completionHandler()
    }
    
    // 📱 Notification reçue en arrière-plan (silent push)
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        
        Task { @MainActor in
            NotificationManager.shared.didReceiveNotification(userInfo)
        }
        
        completionHandler(.newData)
    }
}

// MARK: - MessagingDelegate (Firebase)
extension AppDelegate: MessagingDelegate {
    
    // ✅ Appelé quand le FCM token est reçu ou mis à jour
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        
        Task { @MainActor in
            NotificationManager.shared.didReceiveFCMToken(fcmToken)
        }
    }
}

