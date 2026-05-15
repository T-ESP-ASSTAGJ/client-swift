import Foundation
import Combine
import UIKit

// MARK: - Models

/// Réponse renvoyée par l'endpoint `/mercure/token` du backend.
///
/// Contient un JWT signé, à utiliser comme `Bearer` lors de la souscription au hub.
struct MercureTokenResponse: Decodable {
    let token: String
}

// MARK: - Service

/// Client Mercure (Server-Sent Events) utilisé pour la messagerie temps réel et les notifications.
///
/// `MercureService` ouvre une connexion HTTP long-lived vers le hub Mercure et délivre
/// chaque événement parsé aux handlers enregistrés par topic. Le service est implémenté
/// en singleton car une seule connexion SSE doit être active à la fois pour l'app.
///
/// Le service gère également :
/// - le cache du token Mercure (TTL de 50 min) pour éviter un aller-retour API à chaque reconnexion,
/// - la reconnexion automatique avec backoff exponentiel,
/// - la mise en pause au passage en arrière-plan et la reconnexion au retour au premier plan.
///
/// Cycle de vie typique :
/// 1. ``subscribe(topics:onMessage:)`` est appelé après authentification,
/// 2. Les événements arrivent dans le handler `onMessage`,
/// 3. ``unsubscribe()`` est appelé au logout ou à la mise en arrière-plan prolongée.
@MainActor
class MercureService: NSObject, ObservableObject {

    // MARK: - Singleton
    /// Instance partagée du service Mercure.
    static let shared = MercureService()

    // MARK: - Published Properties
    /// `true` uniquement après réception d'une réponse HTTP 2xx du hub Mercure.
    @Published var isConnected = false

    // MARK: - Private Properties
    /// Session URL dédiée à la souscription SSE en cours.
    ///
    /// Invalidée et recréée à chaque (re)connexion pour casser le retain cycle delegate↔session.
    private var session: URLSession?
    /// Tâche réseau de la souscription en cours, conservée pour pouvoir l'annuler.
    private var dataTask: URLSessionDataTask?
    /// Tampon temporaire des fragments SSE non encore terminés par `\n\n`.
    private var buffer = ""
    /// Handlers à invoquer pour chaque topic souscrit, indexés par nom de topic.
    private var eventHandlers: [String: (Data) -> Void] = [:]

    // Cache du token (évite un aller-retour API à chaque (re)connexion)
    /// JWT Mercure mis en cache pour éviter un appel `/mercure/token` à chaque reconnexion.
    private var mercureToken: String?
    /// Date à laquelle le token courant a été récupéré, utilisée pour le TTL.
    private var tokenFetchedAt: Date?
    /// Durée de validité côté client (50 min). Au-delà, un nouveau token est demandé.
    private let tokenMaxAge: TimeInterval = 50 * 60

    // État pour la reconnexion automatique
    /// Topics actuellement souscrits, conservés pour rejouer la souscription après une coupure.
    private var currentTopics: [String] = []
    /// Closure utilisateur appelée pour chaque événement, conservée pour rejouer après reconnexion.
    private var currentHandler: ((String, Data) -> Void)?
    /// Tâche planifiant la prochaine tentative de reconnexion (backoff exponentiel).
    private var reconnectTask: Task<Void, Never>?
    /// Compteur de tentatives, utilisé pour calculer le délai du backoff exponentiel.
    private var reconnectAttempts: Int = 0
    /// Plafond du délai de reconnexion (30 s) ; au-delà, le backoff arrête de croître.
    private let maxReconnectDelay: TimeInterval = 30

    // Continuations en attente d'une connexion confirmée
    /// Continuations bloquées sur ``waitForConnection(timeout:)``, débloquées dès qu'une
    /// réponse 2xx arrive (ou en cas de timeout).
    private var connectionWaiters: [(Bool) -> Void] = []

    private override init() {
        super.init()
        observeAppLifecycle()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - App Lifecycle

    /// Pose les observateurs `didBecomeActive` et `didEnterBackground` pour mettre en pause
    /// la connexion en arrière-plan et la relancer au retour au premier plan.
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

    /// Relance une connexion SSE quand l'app revient au premier plan, à condition qu'une
    /// souscription soit active (`currentTopics` non vide).
    @objc nonisolated private func handleAppDidBecomeActive() {
        Task { @MainActor in
            guard !currentTopics.isEmpty else { return }
            await connect()
        }
    }

    /// Marque la connexion comme rompue au passage en arrière-plan.
    ///
    /// iOS coupe les sockets en arrière-plan : on remet `isConnected` à `false` pour
    /// ne pas mentir à l'UI.
    @objc nonisolated private func handleAppDidEnterBackground() {
        Task { @MainActor in
            // iOS coupe les sockets en arrière-plan : on évite de mentir à l'UI.
            isConnected = false
        }
    }

    // MARK: - Token

    /// Retourne le token Mercure courant, depuis le cache si encore valide, sinon depuis l'API.
    ///
    /// Le TTL côté client est de ``tokenMaxAge`` (50 min). Passé ce délai, un nouvel appel
    /// `/mercure/token` est effectué via ``APIClient``.
    ///
    /// - Returns: Le JWT à utiliser pour souscrire au hub.
    /// - Throws: Toute ``APIError`` issue de l'appel HTTP sous-jacent.
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

    /// S'abonne à un ou plusieurs topics Mercure et ouvre une connexion SSE.
    ///
    /// La méthode ne retourne qu'une fois la connexion réellement établie (timeout court
    /// de 5 s via ``waitForConnection(timeout:)``). Toute souscription précédente est
    /// annulée avant l'ouverture de la nouvelle. La connexion est rejouée automatiquement
    /// après une coupure réseau ou un retour au premier plan tant qu'``unsubscribe()`` n'a
    /// pas été appelée.
    ///
    /// - Parameters:
    ///   - topics: Liste des topics auxquels souscrire (ex. `"conversations/42"`).
    ///   - onMessage: Closure appelée pour chaque événement reçu, avec le nom du topic et
    ///     le payload brut sous forme de `Data` prêt à décoder en JSON.
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

    /// Attend que la connexion SSE soit confirmée (réponse HTTP 2xx du hub) ou jusqu'au timeout.
    ///
    /// Utilisé par ``subscribe(topics:onMessage:)`` pour ne retourner qu'une fois la
    /// connexion utilisable, et exposé publiquement pour les appelants qui veulent attendre
    /// explicitement (par exemple avant d'envoyer un message).
    ///
    /// - Parameter timeout: Délai maximal d'attente en secondes. `3.0` par défaut.
    /// - Returns: `true` si la connexion a été confirmée avant le timeout, `false` sinon.
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

    /// Ferme la connexion SSE, oublie tous les handlers et stoppe les reconnexions.
    ///
    /// À appeler lors du logout, du passage en arrière-plan prolongé, ou avant un changement
    /// de set de topics.
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

    /// Ouvre une nouvelle connexion SSE vers le hub Mercure avec les topics courants.
    ///
    /// Récupère le token (via le cache si possible), construit la requête `text/event-stream`
    /// avec en-tête `Authorization: Bearer`, et démarre une `URLSessionDataTask`.
    /// Une session précédente est invalidée pour éviter les fuites mémoire.
    /// En cas d'échec de récupération du token, planifie une reconnexion.
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

    /// Planifie une tentative de reconnexion avec backoff exponentiel.
    ///
    /// Le délai double à chaque tentative (1 s, 2 s, 4 s…) et est plafonné par
    /// ``maxReconnectDelay`` (30 s). Aucune reconnexion n'est planifiée si plus aucun
    /// topic n'est souscrit.
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

    /// Notifie toutes les continuations en attente du résultat de la connexion.
    ///
    /// La liste est vidée avant l'appel des waiters pour éviter qu'un waiter qui se
    /// réinscrirait dans sa propre closure ne soit notifié deux fois.
    ///
    /// - Parameter connected: `true` si la connexion est confirmée, `false` en cas d'échec.
    private func notifyWaiters(_ connected: Bool) {
        let waiters = connectionWaiters
        connectionWaiters.removeAll()
        for waiter in waiters {
            waiter(connected)
        }
    }
}

// MARK: - ResumeBox

/// Garde-fou thread-safe garantissant qu'une `CheckedContinuation` est résumée au plus une fois.
///
/// Indispensable pour ``MercureService/waitForConnection(timeout:)`` où deux chemins peuvent
/// tenter de résumer la même continuation : la réponse du serveur et le timer de timeout.
private final class ResumeBox: @unchecked Sendable {
    private var resumed = false
    private let lock = NSLock()

    /// Marque la continuation comme résumée si elle ne l'était pas déjà.
    ///
    /// - Returns: `true` si l'appelant doit effectivement résumer la continuation,
    ///   `false` si une autre tâche l'a déjà fait.
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

    /// Callback du handshake HTTP du flux SSE.
    ///
    /// Marque la connexion comme établie en cas de réponse 2xx et réinitialise le compteur
    /// de reconnexion. Sur `401`/`403`, purge le token en cache pour forcer un refresh à
    /// la prochaine tentative. Les autres erreurs HTTP laissent `isConnected` à `false`.
    nonisolated func urlSession(
        _: URLSession,
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

    /// Callback de réception de fragments du flux SSE.
    ///
    /// Mercure envoie des événements terminés par `\n\n`. Le buffer permet de gérer les
    /// fragments qui arrivent à cheval entre deux callbacks : si le buffer ne se termine
    /// pas par `\n\n`, le dernier morceau incomplet est conservé pour le prochain appel.
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

    /// Parse un événement SSE complet et appelle tous les handlers enregistrés.
    ///
    /// Un événement Mercure peut contenir plusieurs lignes ; seule la ligne `data:` est
    /// utilisée ici (les autres champs comme `id:` ou `event:` ne sont pas exploités).
    /// Comme Mercure ne joint pas le nom de topic au payload côté wire, tous les handlers
    /// sont notifiés et c'est à l'appelant de filtrer dans la closure `onMessage`.
    ///
    /// - Parameter eventString: Bloc d'événement SSE brut (lignes séparées par `\n`).
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

    /// Callback de fin de la `URLSessionTask` SSE.
    ///
    /// Distingue une annulation volontaire (cancel manuel ou ``unsubscribe()``) d'une vraie
    /// coupure. En cas de coupure non volontaire et avec des topics encore actifs, planifie
    /// une reconnexion via ``scheduleReconnect()``.
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
