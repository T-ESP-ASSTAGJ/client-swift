import Foundation
import Combine

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
    
    // ⚠️ TOKEN HARDCODED TEMPORAIREMENT
    private let mercureToken = "eyJhbGciOiJIUzI1NiJ9.eyJtZXJjdXJlIjp7InB1Ymxpc2giOlsiKiJdLCJzdWJzY3JpYmUiOlsiaHR0cHM6Ly9leGFtcGxlLmNvbS9teS1wcml2YXRlLXRvcGljIiwie3NjaGVtZX06Ly97K2hvc3R9L2RlbW8vYm9va3Mve2lkfS5qc29ubGQiLCIvLndlbGwta25vd24vbWVyY3VyZS9zdWJzY3JpcHRpb25zey90b3BpY317L3N1YnNjcmliZXJ9Il0sInBheWxvYWQiOnsidXNlciI6Imh0dHBzOi8vZXhhbXBsZS5jb20vdXNlcnMvZHVuZ2xhcyIsInJlbW90ZUFkZHIiOiIxMjcuMC4wLjEifX19.KKPIikwUzRuB3DTpVw6ajzwSChwFw5omBMmMcWKiDcM"
    
    private let hubURL = "http://10.68.251.169/.well-known/mercure"
    
    private override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// S'abonner à un ou plusieurs topics
    func subscribe(topics: [String], onMessage: @escaping (String, Data) -> Void) {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔌 MERCURE - ABONNEMENT")
        print("   Topics: \(topics.joined(separator: ", "))")
        
        // Construire l'URL avec les topics
        guard var components = URLComponents(string: hubURL) else {
            print("❌ URL invalide: \(hubURL)")
            return
        }
        
        components.queryItems = topics.map { URLQueryItem(name: "topic", value: $0) }
        
        guard let url = components.url else {
            print("❌ Impossible de créer l'URL")
            return
        }
        
        print("   URL: \(url.absoluteString)")
        
        // Créer la requête
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(mercureToken)", forHTTPHeaderField: "Authorization")
        
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
        
        // Démarrer
        dataTask?.cancel() // Annuler la connexion précédente si elle existe
        dataTask = session.dataTask(with: request)
        dataTask?.resume()
        
        isConnected = true
        print("✅ Connexion établie!")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }
    
    /// Se désabonner
    func unsubscribe() {
        dataTask?.cancel()
        dataTask = nil
        isConnected = false
        eventHandlers.removeAll()
        buffer = ""
        print("🔌 Déconnecté de Mercure")
    }
}

// MARK: - URLSessionDataDelegate

extension MercureService: URLSessionDataDelegate {
    
    nonisolated func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let text = String(data: data, encoding: .utf8) else {
            print("⚠️ Impossible de convertir data en String")
            return
        }
        
        Task { @MainActor in
            buffer += text
            
            let lines = buffer.components(separatedBy: "\n")
            
            if !buffer.hasSuffix("\n") {
                if lines.count > 1 {
                    buffer = lines.last ?? ""
                    processLines(Array(lines.dropLast()))
                }
            } else {
                buffer = ""
                processLines(lines)
            }
        }
    }
    
    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        Task { @MainActor in
            if let error = error {
                let nsError = error as NSError
                if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                    print("🔌 Connexion Mercure annulée (normal)")
                    return
                }
                
                print("❌ Mercure error: \(error.localizedDescription)")
                print("   Error domain: \(nsError.domain)")
                print("   Error code: \(nsError.code)")
                isConnected = false
                
                // TODO: Ajouter une reconnexion automatique ici si nécessaire
            } else {
                // Connexion fermée proprement
                print("✅ Connexion Mercure fermée proprement")
                isConnected = false
            }
        }
    }
    
    private func processLines(_ lines: [String]) {
        for line in lines {
            if line.isEmpty { continue }
            
            if line.hasPrefix("data: ") {
                let jsonString = String(line.dropFirst(6))
                
                print("📨 Message Mercure reçu")
                print("   JSON: \(jsonString)")
                
                // Parser le JSON pour extraire le topic (si disponible)
                if let data = jsonString.data(using: .utf8) {
                    // Appeler tous les handlers (on ne peut pas toujours déterminer le topic exact)
                    for (_, handler) in eventHandlers {
                        handler(data)
                    }
                }
            }
        }
    }
}

