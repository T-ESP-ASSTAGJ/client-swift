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
    
    func getCatalogID(for track: Track) async -> String? {
        do {
            // Vérifie d'abord si c'est déjà un ID catalogue (pas "i.")
            let trackID = track.id.rawValue
            if !trackID.hasPrefix("i.") {
                print("✅ Déjà un ID catalogue: \(trackID)")
                return trackID
            }
            
            print("🔍 Track de bibliothèque détecté, recherche dans le catalogue...")
            
            // Récupère les infos du track
            let title = track.title
            let artistName = track.artistName
            
            // Recherche dans le catalogue Apple Music
            let searchTerm = "\(title) \(artistName)"
            var searchRequest = MusicCatalogSearchRequest(term: searchTerm, types: [Song.self])
            searchRequest.limit = 5  // Prend les 5 premiers résultats
            
            let response = try await searchRequest.response()
            
            let songs = response.songs
            guard !songs.isEmpty else {
                print("❌ Aucun résultat trouvé dans le catalogue")
                return nil
            }
            
            // Trouve la meilleure correspondance
            // (idéalement même titre ET même artiste)
            let exactMatch = songs.first { song in
                song.title.lowercased() == title.lowercased() &&
                song.artistName.lowercased() == artistName.lowercased()
            }
            
            if let match = exactMatch {
                let catalogID = match.id.rawValue
                print("✅ Match exact trouvé!")
                print("   Titre: \(match.title)")
                print("   Artiste: \(match.artistName)")
                print("   Catalog ID: \(catalogID)")
                return catalogID
            }
            
            // Si pas de match exact, prend le premier résultat
            guard let firstSong = songs.first else {
                print("❌ Aucun résultat trouvé dans le catalogue")
                return nil
            }
            let catalogID = firstSong.id.rawValue
            print("⚠️ Pas de match exact, meilleur résultat:")
            print("   Titre: \(firstSong.title)")
            print("   Artiste: \(firstSong.artistName)")
            print("   Catalog ID: \(catalogID)")
            return catalogID
            
        } catch {
            print("❌ Erreur lors de la recherche: \(error)")
            return nil
        }
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
