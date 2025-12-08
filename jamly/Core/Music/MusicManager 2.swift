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
    @Published var isLoading = false
    @Published var errorMessage: String?

    func requestAuthorization() async {
        let status = await MusicAuthorization.request()
        authorizationStatus = status

        if status == .authorized {
            await loadPlaylists()
        }
    }

    func loadPlaylists() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let request = MusicLibraryRequest<Playlist>()
            let response = try await request.response()
            playlists = Array(response.items)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}


