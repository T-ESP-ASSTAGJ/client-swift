import Foundation

/// Configuration simple pour Mercure
struct MercureConfig {
    static let hubURL = "http://10.68.252.15:80/.well-known/mercure"
    
    static var token: String {
        SecureStore.shared.retrieve() ?? ""
    }
}
