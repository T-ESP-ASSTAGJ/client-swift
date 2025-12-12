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
    @Published var authorizationStatus: MusicAuthorization.Status = .notDetermined
    @Published var playlists: [Playlist] = []
    @Published var tracks: [Track] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
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
}
