//
//  APIClient.swift
//  jamly
//
//  Created by REVERSS on 06/12/2025.
//

import Foundation

/// Verbe HTTP utilisé pour une requête vers l'API Jamly.
///
/// Chaque cas correspond directement à la valeur attendue par `URLRequest.httpMethod`.
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// Réponse renvoyée par ``APIClient/request(_:method:query:body:additionalHeaders:responseType:)``.
///
/// Encapsule la valeur décodée et le code de statut HTTP afin de permettre aux appelants
/// d'adapter leur logique (par exemple distinguer un `200` d'un `204`).
///
/// - Parameters:
///   - value: La valeur décodée depuis le corps de la réponse.
///   - statusCode: Le code de statut HTTP renvoyé par le serveur.
struct APIResponse<T> {
    let value: T
    let statusCode: Int
}

/// Client HTTP centralisé pour toutes les communications avec l'API Jamly.
///
/// `APIClient` est un singleton qui gère :
/// - La construction des URLs à partir d'un chemin et de paramètres de requête,
/// - L'encodage automatique du corps en JSON,
/// - L'injection du token d'authentification depuis ``SecureStore``,
/// - Le décodage typé de la réponse,
/// - La gestion uniforme des erreurs via ``APIError``,
/// - La déconnexion automatique en cas de réponse `401 Unauthorized`.
///
/// L'instance partagée est accessible via ``shared``. L'initialiseur est privé
/// pour garantir un point d'entrée unique.
final class APIClient {
    /// Instance partagée à utiliser dans toute l'application.
    static let shared = APIClient()

    /// URL de base de l'API, construite à partir de ``Config/baseURL``.
    private let baseURL = URL(string: "\(Config.baseURL)/api")!

    /// Session URL utilisée pour effectuer les appels réseau.
    private let session: URLSession

    /// Stockage sécurisé (Keychain) utilisé pour récupérer le token d'authentification.
    private let secureStore: SecureStore

    /// Crée une nouvelle instance configurée du client.
    ///
    /// - Parameter secureStore: Le stockage sécurisé à utiliser. La valeur par défaut
    ///   est l'instance partagée ``SecureStore/shared``. Permet l'injection d'un mock en test.
    private init(secureStore: SecureStore = .shared) {
        self.secureStore = secureStore
        let config = URLSessionConfiguration.default
        // 5 s était trop court : certains endpoints déclenchent un service externe
        // (ex. envoi d'OTP par SMS sur /auth/request) et dépassent ce délai.
        config.timeoutIntervalForRequest = 30
        config.httpAdditionalHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        self.session = URLSession(configuration: config)
    }

    /// Effectue une requête HTTP générique vers l'API et décode la réponse dans le type demandé.
    ///
    /// Cette méthode est le point d'entrée unique de toutes les communications HTTP.
    /// Elle se charge de :
    /// 1. Construire l'URL finale en combinant ``baseURL``, `path` et `query`,
    /// 2. Sérialiser `body` en JSON si fourni,
    /// 3. Ajouter automatiquement l'en-tête `Authorization` si un token est présent,
    /// 4. Forcer le `Content-Type` à `application/merge-patch+json` pour les requêtes `PATCH` (exigence API Platform),
    /// 5. Décoder la réponse en `T` ou propager une ``APIError`` typée.
    ///
    /// En cas de réponse `401`, le token est supprimé du Keychain et une notification
    /// `.didReceiveUnauthorized` est postée pour déclencher la déconnexion.
    ///
    /// - Parameters:
    ///   - path: Chemin relatif de la ressource (ex. `"users/me"`), sans le préfixe `/api`.
    ///   - method: Verbe HTTP à utiliser. `.get` par défaut.
    ///   - query: Paramètres de requête à ajouter à l'URL. Les valeurs `nil` sont ignorées.
    ///   - body: Corps de la requête à encoder en JSON. Tout type conforme à `Encodable`.
    ///   - additionalHeaders: En-têtes HTTP supplémentaires à fusionner avec ceux par défaut.
    ///   - responseType: Type cible pour le décodage de la réponse. Inféré la plupart du temps.
    /// - Returns: Une ``APIResponse`` contenant la valeur décodée et le code de statut HTTP.
    /// - Throws:
    ///   - ``APIError/invalidURL`` si l'URL ne peut pas être construite.
    ///   - ``APIError/unauthorized`` si le serveur répond `401`.
    ///   - ``APIError/serverError(statusCode:data:)`` pour tout autre statut hors `2xx`.
    ///   - ``APIError/networkError(_:)`` en cas d'échec réseau (timeout, pas de connexion…).
    @discardableResult
    func request<T: Decodable>(
        _ path: String,
        method: HTTPMethod = .get,
        query: [String: String?] = [:],
        body: Encodable? = nil,
        additionalHeaders: [String: String] = [:],
        responseType: T.Type = T.self
    ) async throws -> APIResponse<T> {
        
        // 1) Construire l'URL
        guard var components = URLComponents(url: baseURL.appendingPathComponent(path),
                                             resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        
        if !query.isEmpty {
            components.queryItems = query.compactMap { key, value in
                guard let value else { return nil }
                return URLQueryItem(name: key, value: value)
            }
        }
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        print("➡️ \(method.rawValue) \(url.absoluteString)")
        
        // 2) Body JSON si besoin
        if let body = body {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(AnyEncodable(body))
            
            if let bodyData = request.httpBody {
                print("📦 Body:", String(data: bodyData, encoding: .utf8) ?? "")
            }
        }
        
        // 3) Headers
        var headers: [String: String] = additionalHeaders
        
        // Override Content-Type for PATCH requests
        if method == .patch {
            headers["Content-Type"] = "application/merge-patch+json"
        }

        if let token = secureStore.retrieve(key: "token") {
            headers["Authorization"] = "Bearer \(token)"
        }
        
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // 4) Appel réseau
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.serverError(statusCode: -1, data: data)
            }
            
            let status = httpResponse.statusCode
            print("📥 Response status: \(status)")
            
            let decoder = JSONDecoder()
            
            switch status {
            case 200..<300:
                if status == 204 || data.isEmpty {
                    if T.self == EmptyResponse.self {
                        return APIResponse(value: EmptyResponse() as! T, statusCode: status)
                    }
                }

                let decoded = try decoder.decode(T.self, from: data)
                return APIResponse(value: decoded, statusCode: status)
                
            case 401:
                print("🔒 401 Unauthorized - Posting notification")
                secureStore.delete(key: "token")
                
                await MainActor.run {
                    NotificationCenter.default.post(name: .didReceiveUnauthorized, object: nil)
                }
                
                throw APIError.unauthorized
                
            default:
                if let errorString = String(data: data, encoding: .utf8) {
                    print("❌ Error response: \(errorString)")
                }
                throw APIError.serverError(statusCode: status, data: data)
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            print("❌ Network error: \(error)")
            throw APIError.networkError(error)
        }
    }
}

/// Type vide utilisé comme `responseType` pour les endpoints qui ne renvoient pas de corps
/// (typiquement les réponses `204 No Content`).
struct EmptyResponse: Decodable {}

/// Wrapper permettant de passer une valeur `Encodable` existentielle à `JSONEncoder`.
///
/// Swift n'autorise pas directement l'encodage d'une valeur typée `Encodable` car le protocole
/// possède des exigences associées au type concret. Ce wrapper capture la fonction `encode(to:)`
/// du type sous-jacent dans une closure et la rejoue au moment de l'encodage, ce qui contourne
/// la limitation du compilateur.
private struct AnyEncodable: Encodable {
    /// Closure qui réalise l'encodage en redirigeant vers la valeur d'origine.
    private let encodeFunc: (Encoder) throws -> Void

    /// Construit un wrapper autour d'une valeur `Encodable`.
    ///
    /// - Parameter value: La valeur à encoder lors de l'appel à `encode(to:)`.
    init(_ value: Encodable) {
        self.encodeFunc = value.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeFunc(encoder)
    }
}
