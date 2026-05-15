//
//  SecureStore.swift
//  jamly
//
//  Created by REVERSS on 07/12/2025.
//


import Foundation
import Security

/// Stockage sécurisé basé sur le Keychain iOS.
///
/// Utilisé en priorité pour conserver le token d'authentification entre deux lancements
/// de l'application. Toutes les entrées sont regroupées sous un même `service` Keychain
/// (`com.reverss.jamly`) afin d'être effacées en bloc lors de la déconnexion.
class SecureStore {
    /// Instance partagée. Préférer cette propriété au lieu d'instancier le store directement.
    static let shared = SecureStore()

    /// Identifiant de service utilisé dans toutes les requêtes Keychain de l'app.
    private let service = "com.reverss.jamly"

    /// Enregistre une valeur dans le Keychain pour la clé donnée.
    ///
    /// L'entrée existante pour la même clé est d'abord supprimée afin d'éviter un échec
    /// d'insertion dû à un doublon.
    ///
    /// - Parameters:
    ///   - token: Valeur à stocker (encodée en UTF-8).
    ///   - key: Compte Keychain associé. Par défaut `"token"`.
    func save(token: String, key: String = "token") {
        let data = token.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    /// Récupère une valeur préalablement stockée dans le Keychain.
    ///
    /// - Parameter key: Compte Keychain à lire. Par défaut `"token"`.
    /// - Returns: La valeur décodée en UTF-8, ou `nil` si la clé n'existe pas
    ///   ou si la donnée n'est pas du texte valide.
    func retrieve(key: String = "token") -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)

        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Supprime la valeur associée à la clé donnée.
    ///
    /// L'opération est idempotente : aucune erreur n'est levée si la clé n'existe pas.
    ///
    /// - Parameter key: Compte Keychain à supprimer. Par défaut `"token"`.
    func delete(key: String = "token") {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}
