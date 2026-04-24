//
//  NotificationService.swift
//  NotificationServiceExtension
//
//  Created by Jonathan Dumesnil on 17/04/2026.
//

import UserNotifications
import Intents

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        NSLog("🔔 [NotificationService] Extension appelée!")
        NSLog("🔔 [NotificationService] userInfo: \(request.content.userInfo)")

        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard let bestAttemptContent = bestAttemptContent else {
            NSLog("🔔 [NotificationService] bestAttemptContent est nil")
            contentHandler(request.content)
            return
        }

        let userInfo = request.content.userInfo
        let senderName = bestAttemptContent.title
        let avatarURL = (userInfo["profilePicture"] as? String).flatMap(Self.validURL)
        let postURL = (userInfo["postImage"] as? String).flatMap(Self.validURL)

        NSLog("🔔 [NotificationService] senderName: \(senderName)")
        NSLog("🔔 [NotificationService] avatarURL: \(avatarURL?.absoluteString ?? "nil")")
        NSLog("🔔 [NotificationService] postURL: \(postURL?.absoluteString ?? "nil")")

        // Télécharge avatar et post image en parallèle, puis assemble la notif
        let group = DispatchGroup()
        var avatarData: Data?
        var postImageData: Data?

        if let avatarURL {
            group.enter()
            URLSession.shared.dataTask(with: avatarURL) { data, _, error in
                if let error {
                    NSLog("🔔 [NotificationService] Erreur download avatar: \(error)")
                }
                avatarData = data
                group.leave()
            }.resume()
        }

        if let postURL {
            group.enter()
            URLSession.shared.dataTask(with: postURL) { data, _, error in
                if let error {
                    NSLog("🔔 [NotificationService] Erreur download post image: \(error)")
                }
                postImageData = data
                group.leave()
            }.resume()
        }

        group.notify(queue: .global()) {
            let updatedContent = self.createCommunicationNotification(
                content: bestAttemptContent,
                senderName: senderName,
                imageData: avatarData,
                postImageData: postImageData
            )
            contentHandler(updatedContent)
        }
    }

    private static func validURL(_ string: String) -> URL? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = URL(string: trimmed), url.scheme != nil else { return nil }
        return url
    }

    private func createCommunicationNotification(
        content: UNMutableNotificationContent,
        senderName: String,
        imageData: Data?,
        postImageData: Data? = nil
    ) -> UNNotificationContent {
        let handle = INPersonHandle(value: senderName, type: .unknown)

        var avatar: INImage?
        if let data = imageData {
            // Sauvegarder l'image sur disque et utiliser INImage(url:)
            let tmpFile = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("png")
            do {
                try data.write(to: tmpFile)
                avatar = INImage(url: tmpFile)
                NSLog("🔔 [NotificationService] Avatar créé depuis fichier: \(tmpFile)")
            } catch {
                NSLog("🔔 [NotificationService] Erreur écriture image: \(error)")
                avatar = INImage(imageData: data)
            }
        }

        let sender = INPerson(
            personHandle: handle,
            nameComponents: nil,
            displayName: senderName,
            image: avatar,
            contactIdentifier: nil,
            customIdentifier: nil
        )

        let intent = INSendMessageIntent(
            recipients: nil,
            outgoingMessageType: .outgoingMessageText,
            content: content.body,
            speakableGroupName: nil,
            conversationIdentifier: senderName,
            serviceName: nil,
            sender: sender,
            attachments: nil
        )

        let interaction = INInteraction(intent: intent, response: nil)
        interaction.direction = .incoming

        let semaphore = DispatchSemaphore(value: 0)
        interaction.donate { error in
            if let error = error {
                NSLog("🔔 [NotificationService] Erreur donation: \(error)")
            } else {
                NSLog("🔔 [NotificationService] Donation réussie")
            }
            semaphore.signal()
        }
        semaphore.wait()

        do {
            let updatedContent = try content.updating(from: intent)

            // Ajouter l'image du post en attachment (s'affiche à droite)
            if let postData = postImageData,
               let mutableUpdated = updatedContent.mutableCopy() as? UNMutableNotificationContent {
                let tmpPostFile = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension("jpg")
                try postData.write(to: tmpPostFile)
                let attachment = try UNNotificationAttachment(
                    identifier: "postImage",
                    url: tmpPostFile,
                    options: nil
                )
                mutableUpdated.attachments = [attachment]
                NSLog("🔔 [NotificationService] Communication notification + post image créée avec succès")
                return mutableUpdated
            }

            NSLog("🔔 [NotificationService] Communication notification créée avec succès")
            return updatedContent
        } catch {
            NSLog("🔔 [NotificationService] Erreur updating from intent: \(error)")
            return content
        }
    }

    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
