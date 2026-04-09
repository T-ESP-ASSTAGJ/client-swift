import Foundation

/// Configuration simple pour Mercure
struct MercureConfig {
    static let hubURL = "\(Config.baseURL)/.well-known/mercure"
    
    static var token: String {
        SecureStore.shared.retrieve() ?? ""
    }
}
