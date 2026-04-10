import Foundation
import Combine

// MARK: - Models

/// Réponse de l'API pour le token Mercure
struct MercureTokenResponse: Decodable {
    let token: String
}

// MARK: - Service

/// Service Mercure générique et réutilisable
@MainActor
class MercureService: NSObject, ObservableObject {
    
    // MARK: - Singleton
    static let shared = MercureService()
    
    // MARK: - Published Properties
    @Published var isConnected = false
    
    // MARK: - Private Properties
    private var dataTask: URLSessionDataTask?
    private var buffer = ""
    private var eventHandlers: [String: (Data) -> Void] = [:]
    private var mercureToken: String?
    
    private override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Récupère le token Mercure depuis l'API
    private func fetchMercureToken() async throws -> String {
        // Utiliser APIClient pour gérer l'authentification et SSL
        let response = try await APIClient.shared.request(
            "/mercure/token",
            method: .get,
            responseType: MercureTokenResponse.self
        )
        
        return response.value.token
    }
    
    /// S'abonner à un ou plusieurs topics
    func subscribe(topics: [String], onMessage: @escaping (String, Data) -> Void) async {
        // Récupérer le token Mercure
        do {
            mercureToken = try await fetchMercureToken()
        } catch {
            print("❌ Erreur lors de la récupération du token Mercure: \(error.localizedDescription)")
            return
        }
        
        guard let token = mercureToken else {
            print("❌ Token Mercure non disponible")
            return
        }
        
        // Construire l'URL avec les topics
        guard var components = URLComponents(string: MercureConfig.hubURL) else {
            print("❌ URL Mercure invalide: \(MercureConfig.hubURL)")
            return
        }
        
        components.queryItems = topics.map { URLQueryItem(name: "topic", value: $0) }
        
        guard let url = components.url else {
            print("❌ Impossible de créer l'URL Mercure")
            return
        }
        
        // Créer la requête
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Sauvegarder le handler pour chaque topic
        for topic in topics {
            eventHandlers[topic] = { data in
                onMessage(topic, data)
            }
        }
        
        // Créer la session
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = .infinity
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        
        // Démarrer la connexion
        dataTask?.cancel()
        dataTask = session.dataTask(with: request)
        dataTask?.resume()
        
        isConnected = true
    }
    
    func unsubscribe() {
        dataTask?.cancel()
        dataTask = nil
        isConnected = false
        eventHandlers.removeAll()
        buffer = ""
    }
}

// MARK: - URLSessionDataDelegate

extension MercureService: URLSessionDataDelegate {
    
    nonisolated func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let text = String(data: data, encoding: .utf8) else { return }
        
        Task { @MainActor in
            buffer += text
            
            // Parser les événements SSE (Server-Sent Events)
            let events = buffer.components(separatedBy: "\n\n")
            
            // Si le buffer ne se termine pas par \n\n, garder le dernier élément incomplet
            if !buffer.hasSuffix("\n\n") {
                buffer = events.last ?? ""
            } else {
                buffer = ""
            }
            
            // Traiter chaque événement complet
            for event in events.dropLast() where !event.isEmpty {
                parseSSEEvent(event)
            }
        }
    }
    
    /// Parse un événement SSE et appelle le handler approprié
    @MainActor
    private func parseSSEEvent(_ eventString: String) {
        var data: String?
        
        let lines = eventString.components(separatedBy: "\n")
        
        for line in lines {
            if line.hasPrefix("data:") {
                let startIndex = line.index(line.startIndex, offsetBy: 5)
                data = String(line[startIndex...]).trimmingCharacters(in: .whitespaces)
            }
        }
        
        guard let dataString = data,
              let dataJson = dataString.data(using: .utf8) else {
            return
        }
        
        // Appeler tous les handlers
        for (_, handler) in eventHandlers {
            handler(dataJson)
        }
    }
    
    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        Task { @MainActor in
            if let error = error {
                let nsError = error as NSError
                // Ignorer l'erreur de cancellation (normal)
                if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                    return
                }
                
                print("❌ Erreur Mercure: \(error.localizedDescription)")
                isConnected = false
            } else {
                isConnected = false
            }
        }
    }
}


