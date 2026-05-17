import Foundation

/// Configuration du hub Mercure utilisée par ``MercureService``.
///
/// Centralise l'URL du hub et l'accès au token JWT d'authentification. Le token est lu à
/// la volée depuis ``SecureStore`` afin de toujours refléter l'état courant
/// (utile en cas de rotation après refresh).
struct MercureConfig {
    /// URL complète du hub Mercure exposé par le backend Jamly.
    static let hubURL = "\(Config.baseURL)/.well-known/mercure"

    /// Token utilisateur courant lu depuis le Keychain.
    ///
    /// Retourne une chaîne vide en l'absence de token, ce qui provoquera une erreur
    /// d'authentification au moment de la souscription au hub.
    static var token: String {
        SecureStore.shared.retrieve() ?? ""
    }
}
