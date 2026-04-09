//
//  MusicStatsService.swift
//  jamly
//

import Foundation
import MusicKit

final class MusicStatsService {

    // MARK: - Top Tracks

    func fetchTopTracks(limit: Int = 10) async throws -> [Song] {
        var request = MusicLibraryRequest<Song>()
        request.sort(by: \.playCount, ascending: false)
        request.limit = limit
        let response = try await request.response()
        return Array(response.items)
    }

    // MARK: - Top Artists

    func fetchTopArtists(limit: Int = 10) async throws -> [ArtistStat] {
        let songs = try await fetchLibrarySongs()

        var counts: [String: (playCount: Int, artwork: Artwork?)] = [:]
        for song in songs {
            let plays = song.playCount ?? 0
            let existing = counts[song.artistName]
            counts[song.artistName] = (
                playCount: (existing?.playCount ?? 0) + plays,
                artwork: existing?.artwork ?? song.artwork
            )
        }

        return counts
            .map { ArtistStat(id: $0.key, name: $0.key, playCount: $0.value.playCount, artwork: $0.value.artwork) }
            .sorted { $0.playCount > $1.playCount }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Top Albums

    func fetchTopAlbums(limit: Int = 10) async throws -> [AlbumStat] {
        let songs = try await fetchLibrarySongs()

        // Key = "albumTitle|||artistName" to differentiate same-named albums
        var counts: [String: (title: String, artistName: String, playCount: Int, artwork: Artwork?)] = [:]
        for song in songs {
            guard let albumTitle = song.albumTitle else { continue }
            let key = "\(albumTitle)|||\(song.artistName)"
            let plays = song.playCount ?? 0
            let existing = counts[key]
            counts[key] = (
                title: albumTitle,
                artistName: song.artistName,
                playCount: (existing?.playCount ?? 0) + plays,
                artwork: existing?.artwork ?? song.artwork
            )
        }

        return counts
            .map { AlbumStat(id: $0.key, title: $0.value.title, artistName: $0.value.artistName, playCount: $0.value.playCount, artwork: $0.value.artwork) }
            .sorted { $0.playCount > $1.playCount }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Top Genres

    func fetchTopGenres(limit: Int = 10) async throws -> [GenreStat] {
        let songs = try await fetchLibrarySongs()

        var counts: [String: Int] = [:]
        for song in songs {
            guard let genre = song.genreNames.first else { continue }
            counts[genre, default: 0] += song.playCount ?? 0
        }

        return counts
            .map { GenreStat(id: $0.key, name: $0.key, playCount: $0.value) }
            .sorted { $0.playCount > $1.playCount }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Total Listening Time

    /// Returns the estimated total listening time in seconds: Σ (playCount × duration)
    func fetchTotalListeningTime() async throws -> TimeInterval {
        let songs = try await fetchLibrarySongs()
        return songs.reduce(0) { total, song in
            total + Double(song.playCount ?? 0) * (song.duration ?? 0)
        }
    }

    // MARK: - Recent History

    func fetchRecentHistory(limit: Int = 10) async throws -> [Song] {
        var request = MusicRecentlyPlayedRequest<Song>()
        request.limit = limit
        let response = try await request.response()
        return Array(response.items)
    }

    // MARK: - Private

    /// Fetches a large batch of library songs used for aggregation.
    private func fetchLibrarySongs(batchSize: Int = 2000) async throws -> [Song] {
        var request = MusicLibraryRequest<Song>()
        request.limit = batchSize
        let response = try await request.response()
        return Array(response.items)
    }
}
