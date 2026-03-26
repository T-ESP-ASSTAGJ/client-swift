import Foundation

/// Configuration simple pour Mercure
struct MercureConfig {
    static let hubURL = "http://ip-locale:80/.well-known/mercure"
    
    static var token: String {
        SecureStore.shared.retrieve() ?? ""
    }
}
