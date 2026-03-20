//
//  APIClient.swift
//  jamly
//
//  Created by REVERSS on 06/12/2025.
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

struct APIResponse<T> {
    let value: T
    let statusCode: Int
}

final class APIClient {
    static let shared = APIClient()
    
    private let baseURL = URL(string: "http:/10.68.252.2:80/api")!
    private let session: URLSession
    private let secureStore: SecureStore
    
    private init(secureStore: SecureStore = .shared) {
        self.secureStore = secureStore
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        config.httpAdditionalHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        self.session = URLSession(configuration: config)
    }
    
    // Méthode générique pour toutes les requêtes
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
                
                // Poster la notification sur le main thread
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

// Pour gérer les endpoints qui ne renvoient pas de body
struct EmptyResponse: Decodable {}

/// Permet de passer "n'importe quel Encodable" dans `body`
private struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void
    
    init(_ value: Encodable) {
        self.encodeFunc = value.encode
    }
    
    func encode(to encoder: Encoder) throws {
        try encodeFunc(encoder)
    }
}
