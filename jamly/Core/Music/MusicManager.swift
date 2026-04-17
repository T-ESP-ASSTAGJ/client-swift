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

@MainActor
final class MusicManager: ObservableObject {
    @Published var authorizationStatus: MusicAuthorization.Status = .notDetermined
    @Published var playlists: [Playlist] = []
    @Published var tracks: [Track] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var isPlaying = false
    @Published var isConnected: Bool = false

    private var player: AVPlayer?
    private var currentSongId: String?
    private var playTask: Task<Void, Never>?
    private var endObserver: NSObjectProtocol?
    private var backgroundObserver: NSObjectProtocol?

    private var previewUrlCache: [String: URL] = [:]

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

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("⚠️ AVAudioSession config failed: \(error)")
        }
    }

    // MARK: - Authorization

    func checkAuthorizationStatus() async -> MusicAuthorization.Status {
        let status = MusicAuthorization.currentStatus
        authorizationStatus = status
        return status
    }

    func requestAuthorization() async {
        let status = await MusicAuthorization.request()
        authorizationStatus = status

        if status == .authorized {
            isConnected = true
            await loadPlaylists()
        }
    }

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

    func pause() {
        playTask?.cancel()
        player?.pause()
        isPlaying = false
    }

    func play() async {
        player?.play()
        isPlaying = true
    }
}
