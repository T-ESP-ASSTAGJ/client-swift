//
//  ProfileStatsViewModel.swift
//  jamly
//

import Foundation
import Combine
import MusicKit

/// ViewModel de la section statistiques d'écoute du profil.
///
/// Agrège les données fournies par ``MusicStatsService`` : top morceaux, top artistes,
/// historique récent et temps d'écoute total. Toutes les requêtes sont parallélisées via
/// `async let` pour réduire la latence d'affichage.
@MainActor
final class ProfileStatsViewModel: ObservableObject {
    @Published var topTracks: [Song] = []
    @Published var topArtists: [ArtistStat] = []
    @Published var recentHistory: [Song] = []
    @Published var totalListeningTime: TimeInterval = 0
    @Published var isLoading = false
    /// `false` quand l'utilisateur n'a pas connecté/autorisé Apple Music : la vue affiche
    /// alors un empty state au lieu de statistiques vides.
    @Published var isAppleMusicConnected = true

    private let statsService = MusicStatsService()

    /// Temps d'écoute total formaté pour l'affichage (`"3h 25min"`, `"2j 4h"`, etc.).
    ///
    /// Retourne `"—"` quand aucune écoute n'est encore comptabilisée — l'iCloud play-count
    /// peut tarder à se synchroniser sur une session fraîche.
    var formattedListeningTime: String {
        let totalSeconds = Int(totalListeningTime)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        guard hours > 0 || minutes > 0 else { return "—" }
        if hours == 0 { return "\(minutes)min" }
        if hours < 24 { return "\(hours)h \(minutes)min" }
        let days = hours / 24
        return "\(days)j \(hours % 24)h"
    }

    /// Charge toutes les statistiques d'écoute en parallèle.
    ///
    /// Ne fait rien si l'autorisation MusicKit n'est pas accordée. Les erreurs sont logguées
    /// mais n'interrompent pas le chargement des autres jeux de données (chacun a son `try`
    /// propre via les `async let`).
    func loadStats() async {
        guard MusicAuthorization.currentStatus == .authorized else {
            isAppleMusicConnected = false
            return
        }
        isAppleMusicConnected = true
        isLoading = true
        defer { isLoading = false }

        do {
            async let tracks = statsService.fetchTopTracks(limit: 5)
            async let artists = statsService.fetchTopArtists(limit: 5)
            async let time = statsService.fetchTotalListeningTime()
            async let recent = statsService.fetchRecentHistory(limit: 10)

            topTracks = try await tracks
            topArtists = try await artists
            totalListeningTime = try await time
            recentHistory = try await recent
        } catch {
            print("❌ Stats load error: \(error)")
        }
    }
}
