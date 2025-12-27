//
//  MusicManager.swift
//  jamly
//
//  Created by REVERSS on 06/12/2025.
//

import Foundation
import MusicKit
import Combine

@MainActor
final class MusicManager: ObservableObject {
    // ✅ Expose le player pour qu'on puisse l'utiliser dans HomeFeed
    let player = ApplicationMusicPlayer.shared
    
    @Published var authorizationStatus: MusicAuthorization.Status = .notDetermined
    @Published var playlists: [Playlist] = []
    @Published var tracks: [Track] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // ✅ Track actuellement en lecture
    @Published var currentTrack: Song?
    @Published var isPlaying = false
    
    private var playTask: Task<Void, Never>?
    
    // ✅ NOUVEAU: Vérifie le statut actuel SANS demander l'autorisation
    func checkAuthorizationStatus() async -> MusicAuthorization.Status {
        let status = MusicAuthorization.currentStatus
        authorizationStatus = status
        return status
    }
    
    // ✅ Demande l'autorisation (avec prompt si notDetermined)
    func requestAuthorization() async {
        let status = await MusicAuthorization.request()
        authorizationStatus = status
        
        if status == .authorized {
            await loadPlaylists()
        }
    }
    
    func loadPlaylists() async {
        // ✅ Ne charge que si autorisé
        guard authorizationStatus == .authorized else {
            print("⚠️ Pas autorisé, skip loadPlaylists")
            return
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Charge les playlists avec les propriétés de base
            let request = MusicLibraryRequest<Playlist>()
            let response = try await request.response()
            
            print("📋 Found \(response.items.count) playlists")
            
            // Charge les détails pour chaque playlist
            var detailedPlaylists: [Playlist] = []
            for playlist in response.items {
                do {
                    // Charge artwork, description, curatorName
                    let detailed = try await playlist.with([.tracks])
                    detailedPlaylists.append(detailed)
                } catch {
                    // Si ça échoue pour une playlist, ajoute quand même la version de base
                    print("⚠️ Error loading details for playlist \(playlist.name): \(error)")
                    detailedPlaylists.append(playlist)
                }
            }
            
            // ⚠️ IMPORTANT: Assigne les playlists chargées !
            playlists = detailedPlaylists
            
            print("✅ Loaded \(playlists.count) playlists with details")
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error loading playlists: \(error)")
        }
    }
    
    func playTrackById(_ trackId: String) async {
        // ✅ Annule la tâche précédente si elle existe
        playTask?.cancel()
        
        playTask = Task { @MainActor in
            do {
                let status = await MusicAuthorization.request()
                guard status == .authorized else {
                    print("❌ Apple Music non autorisé")
                    return
                }
                
                // ✅ Vérifie que la tâche n'a pas été annulée
                guard !Task.isCancelled else {
                    print("⏭️ Lecture annulée")
                    return
                }
                
                let musicItemID = MusicItemID(trackId)
                var request = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: musicItemID)
                let response = try await request.response()
                
                // ✅ Vérifie encore que la tâche n'a pas été annulée
                guard !Task.isCancelled else {
                    print("⏭️ Lecture annulée après recherche")
                    return
                }
                
                guard let song = response.items.first else {
                    print("❌ Track introuvable avec ID: \(trackId)")
                    return
                }
                
                print("🎵 Lecture: \(song.title) - \(song.artistName)")
                
                // Configure et joue
                player.queue = [song]
                try await player.play()
                
                currentTrack = song
                isPlaying = true
                
            } catch is CancellationError {
                print("⏭️ Lecture annulée (CancellationError)")
            } catch {
                print("❌ Erreur lecture track: \(error)")
            }
        }
        
        await playTask?.value
    }
    
    // ✅ Pause la musique
    func pause() {
        playTask?.cancel() // ✅ Annule aussi la tâche en cours
        player.pause()
        isPlaying = false
    }
    
    // ✅ Resume la musique
    func play() async {
        do {
            try await player.play()
            isPlaying = true
        } catch {
            print("❌ Erreur play: \(error)")
        }
    }
}
