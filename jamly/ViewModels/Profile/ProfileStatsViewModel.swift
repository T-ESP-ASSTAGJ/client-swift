//
//  ProfileStatsViewModel.swift
//  jamly
//

import Foundation
import Combine
import MusicKit

@MainActor
final class ProfileStatsViewModel: ObservableObject {
    @Published var topTracks: [Song] = []
    @Published var topArtists: [ArtistStat] = []
    @Published var recentHistory: [Song] = []
    @Published var totalListeningTime: TimeInterval = 0
    @Published var isLoading = false

    private let statsService = MusicStatsService()

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

    func loadStats() async {
        guard MusicAuthorization.currentStatus == .authorized else { return }
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
