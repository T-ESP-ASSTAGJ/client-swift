//
//  MusicManager.swift
//  jamly
//
//  Created by REVERSS on 06/12/2025.
//

import Foundation
import MusicKit
import AVFoundation
import Combine
import UIKit

/// Façade au-dessus de MusicKit et AVPlayer pour intégrer Apple Music dans Jamly.
///
/// `MusicManager` couvre trois responsabilités complémentaires :
/// - **Autorisation** : demande et suit le statut MusicKit (`MusicAuthorization`),
/// - **Bibliothèque** : charge les playlists locales avec leurs morceaux,
/// - **Lecture de previews** : utilise `AVPlayer` pour jouer les 30 s d'extrait fournies
///   par Apple Music, sans nécessiter d'abonnement actif côté utilisateur.
///
/// L'instance est partagée dans l'arbre SwiftUI via `@EnvironmentObject`.
@MainActor
final class MusicManager: ObservableObject {
    /// Statut d'autorisation MusicKit courant.
    @Published var authorizationStatus: MusicAuthorization.Status = .notDetermined
    /// Playlists de la bibliothèque utilisateur, chargées avec leurs morceaux détaillés.
    @Published var playlists: [Playlist] = []
    /// Morceaux additionnels exposés en cache (utilisés ponctuellement par les pickers).
    @Published var tracks: [Track] = []
    /// `true` pendant un chargement de bibliothèque.
    @Published var isLoading = false
    /// Dernier message d'erreur à afficher dans l'UI.
    @Published var errorMessage: String?

    /// `true` si un preview est en cours de lecture.
    @Published var isPlaying = false
    /// `true` quand l'utilisateur a autorisé Apple Music et que la bibliothèque a été chargée.
    @Published var isConnected: Bool = false

    private var player: AVPlayer?
    /// Identifiant du morceau actuellement lu, ou `nil` si rien ne joue.
    @Published var currentSongId: String?
    /// Tâche de lecture en cours, conservée pour pouvoir l'annuler lors d'un changement rapide
    /// de morceau (ex. scroll de feed).
    private var playTask: Task<Void, Never>?
    /// Observateur posé sur `AVPlayerItemDidPlayToEndTime` pour boucler le preview.
    private var endObserver: NSObjectProtocol?
    /// Observateur posé sur `UIApplication.didEnterBackgroundNotification` pour pauser
    /// automatiquement la lecture quand l'app passe en arrière-plan.
    private var backgroundObserver: NSObjectProtocol?

    /// Cache des URLs de preview résolues via MusicKit, indexées par `songId`.
    private var previewUrlCache: [String: URL] = [:]

    /// Configure la session audio et pose les observateurs de cycle de vie.
    init() {
        configureAudioSession()
        backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.pause() }
        }
    }

    deinit {
        if let token = endObserver { NotificationCenter.default.removeObserver(token) }
        if let token = backgroundObserver { NotificationCenter.default.removeObserver(token) }
    }

    /// Active la session audio en mode `.playback` avec `.mixWithOthers`
    /// pour ne pas couper d'autres lectures en cours sur l'appareil.
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("⚠️ AVAudioSession config failed: \(error)")
        }
    }

    // MARK: - Authorization

    /// Lit le statut d'autorisation Apple Music sans ouvrir de prompt système.
    ///
    /// - Returns: Le statut courant, également propagé dans ``authorizationStatus``.
    func checkAuthorizationStatus() async -> MusicAuthorization.Status {
        let status = MusicAuthorization.currentStatus
        authorizationStatus = status
        return status
    }

    /// Demande l'autorisation Apple Music à l'utilisateur (prompt système).
    ///
    /// En cas d'acceptation, marque le manager comme connecté et déclenche le chargement
    /// initial des playlists.
    func requestAuthorization() async {
        let status = await MusicAuthorization.request()
        authorizationStatus = status

        if status == .authorized {
            isConnected = true
            await loadPlaylists()
        }
    }

    /// Déconnecte le manager d'Apple Music côté app (vide la bibliothèque locale et arrête
    /// la lecture).
    ///
    /// - Note: Le système n'expose pas d'API pour révoquer programmatiquement l'autorisation.
    ///   L'utilisateur doit passer par les Réglages iOS pour le faire.
    func disconnect() {
        isConnected = false
        playlists = []
        tracks = []
        pause()
        authorizationStatus = .notDetermined
        print("🎵 Disconnected from Apple Music - playlists cleared")
        print("⚠️ Note: To fully revoke access, go to iOS Settings > [Your App] > Media & Apple Music")
    }

    // MARK: - Library Playlists

    /// Charge les playlists de la bibliothèque utilisateur et leurs morceaux associés.
    ///
    /// Pour chaque playlist, tente d'enrichir l'objet via `playlist.with([.tracks])`.
    /// Si l'appel échoue, la playlist non détaillée est conservée afin d'éviter un trou
    /// dans la liste affichée.
    func loadPlaylists() async {
        guard authorizationStatus == .authorized else {
            print("⚠️ Pas autorisé, skip loadPlaylists")
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let request = MusicLibraryRequest<Playlist>()
            let response = try await request.response()

            var detailedPlaylists: [Playlist] = []
            for playlist in response.items {
                do {
                    let detailed = try await playlist.with([.tracks])
                    detailedPlaylists.append(detailed)
                } catch {
                    detailedPlaylists.append(playlist)
                }
            }
            playlists = detailedPlaylists
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error loading playlists: \(error)")
        }
    }

    // MARK: - Preview Playback (AVPlayer, in-app only)

    /// Lance la lecture de l'extrait (30 s) du morceau correspondant à `songId`.
    ///
    /// Comportement détaillé :
    /// - Une chaîne vide met la lecture en pause,
    /// - Relancer le morceau déjà en cours ne fait que reprendre la lecture,
    /// - Toute lecture précédente est annulée avant d'en démarrer une nouvelle,
    /// - Le preview boucle automatiquement en fin de piste.
    ///
    /// - Parameter songId: Identifiant catalogue Apple Music du morceau.
    func playPreview(songId: String) async {
        if songId.isEmpty {
            pause()
            return
        }

        if currentSongId == songId, let player = player {
            if !isPlaying {
                player.play()
                isPlaying = true
            }
            return
        }

        playTask?.cancel()

        playTask = Task { @MainActor in
            guard !Task.isCancelled else { return }

            guard let previewUrl = await fetchPreviewUrl(songId: songId) else {
                print("❌ No preview available for songId: \(songId)")
                return
            }

            guard !Task.isCancelled else { return }

            if let token = endObserver {
                NotificationCenter.default.removeObserver(token)
                endObserver = nil
            }

            let item = AVPlayerItem(url: previewUrl)
            let newPlayer = AVPlayer(playerItem: item)
            newPlayer.automaticallyWaitsToMinimizeStalling = true

            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { _ in
                newPlayer.seek(to: .zero)
                newPlayer.play()
            }

            guard !Task.isCancelled else { return }

            player = newPlayer
            currentSongId = songId
            newPlayer.play()
            isPlaying = true
        }

        await playTask?.value
    }

    /// Résout l'URL du preview pour un identifiant catalogue donné.
    ///
    /// Le résultat est mis en cache afin d'éviter des appels MusicKit répétés lors d'un scroll
    /// rapide.
    ///
    /// - Parameter songId: Identifiant catalogue Apple Music.
    /// - Returns: L'URL du fichier preview, ou `nil` si aucun preview n'est disponible.
    private func fetchPreviewUrl(songId: String) async -> URL? {
        if let cached = previewUrlCache[songId] {
            return cached
        }

        do {
            let musicItemID = MusicItemID(songId)
            let request = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: musicItemID)
            let response = try await request.response()

            guard let song = response.items.first,
                  let previewUrl = song.previewAssets?.first?.url else {
                return nil
            }

            previewUrlCache[songId] = previewUrl
            return previewUrl
        } catch {
            print("❌ Error fetching preview for \(songId): \(error)")
            return nil
        }
    }

    // MARK: - Catalog Search (for MusicPickerView)

    /// Recherche des morceaux dans le catalogue Apple Music.
    ///
    /// - Parameters:
    ///   - term: Texte de recherche libre (titre, artiste, etc.).
    ///   - limit: Nombre maximum de résultats à retourner. Par défaut `25`.
    /// - Returns: Liste des morceaux trouvés ; vide en cas d'erreur ou de résultats vides.
    func searchCatalog(term: String, limit: Int = 25) async -> [Song] {
        do {
            var request = MusicCatalogSearchRequest(term: term, types: [Song.self])
            request.limit = limit
            let response = try await request.response()
            return Array(response.songs)
        } catch {
            print("❌ Catalog search error: \(error)")
            return []
        }
    }

    // MARK: - Get Catalog ID from library track

    /// Convertit un identifiant de morceau de bibliothèque (`i.xxx`) en identifiant catalogue.
    ///
    /// Les morceaux issus de la bibliothèque utilisateur ont des identifiants préfixés `i.`
    /// qui ne sont pas utilisables par les autres clients. Cette méthode recherche le morceau
    /// dans le catalogue par titre + artiste et tente une correspondance exacte ; à défaut,
    /// le premier résultat est retourné.
    ///
    /// - Parameter track: Morceau issu de la bibliothèque.
    /// - Returns: L'identifiant catalogue (sans préfixe), ou `nil` si aucun résultat.
    func getCatalogID(for track: Track) async -> String? {
        let trackID = track.id.rawValue
        if !trackID.hasPrefix("i.") {
            return trackID
        }

        let searchTerm = "\(track.title) \(track.artistName)"
        var searchRequest = MusicCatalogSearchRequest(term: searchTerm, types: [Song.self])
        searchRequest.limit = 5

        do {
            let response = try await searchRequest.response()
            let songs = response.songs

            let exactMatch = songs.first { song in
                song.title.lowercased() == track.title.lowercased() &&
                song.artistName.lowercased() == track.artistName.lowercased()
            }

            return (exactMatch ?? songs.first)?.id.rawValue
        } catch {
            print("❌ Error searching catalog: \(error)")
            return nil
        }
    }

    // MARK: - Controls

    /// Met la lecture en pause et annule toute tâche de préparation en cours.
    func pause() {
        playTask?.cancel()
        player?.pause()
        isPlaying = false
    }

    /// Reprend la lecture du morceau actuellement chargé.
    ///
    /// N'a aucun effet si aucun morceau n'a été préparé via ``playPreview(songId:)``.
    func play() async {
        player?.play()
        isPlaying = true
    }
}
