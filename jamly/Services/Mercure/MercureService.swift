import Foundation
import Combine
import UIKit

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
    /// `true` uniquement après réception d'une réponse HTTP 2xx du hub Mercure.
    @Published var isConnected = false

    // MARK: - Private Properties
    private var session: URLSession?
    private var dataTask: URLSessionDataTask?
    private var buffer = ""
    private var eventHandlers: [String: (Data) -> Void] = [:]

    // Cache du token (évite un aller-retour API à chaque (re)connexion)
    private var mercureToken: String?
    private var tokenFetchedAt: Date?
    private let tokenMaxAge: TimeInterval = 50 * 60

    // État pour la reconnexion automatique
    private var currentTopics: [String] = []
    private var currentHandler: ((String, Data) -> Void)?
    private var reconnectTask: Task<Void, Never>?
    private var reconnectAttempts: Int = 0
    private let maxReconnectDelay: TimeInterval = 30

    // Continuations en attente d'une connexion confirmée
    private var connectionWaiters: [(Bool) -> Void] = []

    private override init() {
        super.init()
        observeAppLifecycle()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - App Lifecycle

    private func observeAppLifecycle() {
        let center = NotificationCenter.default
        center.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    @objc nonisolated private func handleAppDidBecomeActive() {
        Task { @MainActor in
            guard !currentTopics.isEmpty else { return }
            await connect()
        }
    }

    @objc nonisolated private func handleAppDidEnterBackground() {
        Task { @MainActor in
            // iOS coupe les sockets en arrière-plan : on évite de mentir à l'UI.
            isConnected = false
        }
    }

    // MARK: - Token

    private func getMercureToken() async throws -> String {
        if let token = mercureToken,
           let fetchedAt = tokenFetchedAt,
           Date().timeIntervalSince(fetchedAt) < tokenMaxAge {
            return token
        }

        let response = try await APIClient.shared.request(
            "/mercure/token",
            method: .get,
            responseType: MercureTokenResponse.self
        )

        mercureToken = response.value.token
        tokenFetchedAt = Date()
        return response.value.token
    }

    // MARK: - Public API

    /// S'abonne à un ou plusieurs topics. La méthode ne retourne qu'une fois la
    /// connexion SSE réellement établie (ou après un timeout court).
    func subscribe(topics: [String], onMessage: @escaping (String, Data) -> Void) async {
        currentTopics = topics
        currentHandler = onMessage
        eventHandlers.removeAll()
        for topic in topics {
            eventHandlers[topic] = { data in onMessage(topic, data) }
        }
        await connect()
        _ = await waitForConnection(timeout: 5.0)
    }

    /// Attend que la connexion SSE soit confirmée (ou jusqu'au `timeout`).
    /// Retourne `true` si connectée, `false` en cas de timeout.
    func waitForConnection(timeout: TimeInterval = 3.0) async -> Bool {
        if isConnected { return true }

        return await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            let box = ResumeBox()
            let resume: (Bool) -> Void = { value in
                if box.tryResume() {
                    continuation.resume(returning: value)
                }
            }
            connectionWaiters.append(resume)

            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                resume(false)
            }
        }
    }

    func unsubscribe() {
        reconnectTask?.cancel()
        reconnectTask = nil
        dataTask?.cancel()
        dataTask = nil
        session?.invalidateAndCancel()
        session = nil
        isConnected = false
        eventHandlers.removeAll()
        currentTopics = []
        currentHandler = nil
        reconnectAttempts = 0
        buffer = ""
        notifyWaiters(false)
    }

    // MARK: - Connection

    private func connect() async {
        reconnectTask?.cancel()
        reconnectTask = nil

        guard !currentTopics.isEmpty else { return }

        let token: String
        do {
            token = try await getMercureToken()
        } catch {
            print("❌ Erreur lors de la récupération du token Mercure: \(error.localizedDescription)")
            // Force le rafraîchissement au prochain essai
            mercureToken = nil
            tokenFetchedAt = nil
            scheduleReconnect()
            return
        }

        guard var components = URLComponents(string: MercureConfig.hubURL) else {
            print("❌ URL Mercure invalide: \(MercureConfig.hubURL)")
            return
        }

        components.queryItems = currentTopics.map { URLQueryItem(name: "topic", value: $0) }

        guard let url = components.url else {
            print("❌ Impossible de créer l'URL Mercure")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = .infinity

        // Invalide la session précédente pour casser le retain cycle delegate↔session.
        session?.invalidateAndCancel()
        let newSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        session = newSession

        dataTask?.cancel()
        buffer = ""
        let task = newSession.dataTask(with: request)
        dataTask = task
        task.resume()
        // `isConnected` est passé à true uniquement quand le hub répond en 2xx
        // (cf. urlSession(_:dataTask:didReceive:completionHandler:)).
    }

    private func scheduleReconnect() {
        reconnectTask?.cancel()
        guard !currentTopics.isEmpty else { return }

        reconnectAttempts += 1
        let delay = min(pow(2.0, Double(reconnectAttempts - 1)), maxReconnectDelay)

        reconnectTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await connect()
        }
    }

    private func notifyWaiters(_ connected: Bool) {
        let waiters = connectionWaiters
        connectionWaiters.removeAll()
        for waiter in waiters {
            waiter(connected)
        }
    }
}

// MARK: - ResumeBox

private final class ResumeBox: @unchecked Sendable {
    private var resumed = false
    private let lock = NSLock()
    func tryResume() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if resumed { return false }
        resumed = true
        return true
    }
}

// MARK: - URLSessionDataDelegate

extension MercureService: URLSessionDataDelegate {

    nonisolated func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        completionHandler(.allow)
        let receivedTask = dataTask
        Task { @MainActor in
            // Ignore les events des tasks supplantées par une nouvelle connexion
            guard receivedTask === self.dataTask else { return }

            if let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) {
                isConnected = true
                reconnectAttempts = 0
                notifyWaiters(true)
            } else if let http = response as? HTTPURLResponse {
                print("❌ Mercure HTTP \(http.statusCode)")
                isConnected = false
                if http.statusCode == 401 || http.statusCode == 403 {
                    // Token rejeté : on le purge pour forcer un refresh
                    mercureToken = nil
                    tokenFetchedAt = nil
                }
            }
        }
    }

    nonisolated func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let receivedTask = dataTask
        guard let text = String(data: data, encoding: .utf8) else { return }

        Task { @MainActor in
            guard receivedTask === self.dataTask else { return }

            buffer += text

            // Parser les événements SSE (Server-Sent Events)
            let events = buffer.components(separatedBy: "\n\n")

            // Si le buffer ne se termine pas par \n\n, garder le dernier élément incomplet
            if !buffer.hasSuffix("\n\n") {
                buffer = events.last ?? ""
            } else {
                buffer = ""
            }

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

        for (_, handler) in eventHandlers {
            handler(dataJson)
        }
    }

    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let completedTask = task
        Task { @MainActor in
            guard completedTask === self.dataTask else { return }

            let isCancellation: Bool
            if let nsError = error as NSError? {
                isCancellation = (nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled)
                if !isCancellation {
                    print("❌ Erreur Mercure: \(nsError.localizedDescription)")
                }
            } else {
                isCancellation = false
            }

            isConnected = false

            // Reconnexion si le close n'était pas volontaire et qu'on a toujours des topics
            if !currentTopics.isEmpty && !isCancellation {
                scheduleReconnect()
            } else {
                notifyWaiters(false)
            }
        }
    }
}
