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

    /// Returns the estimated total listening time in seconds: Σ (playCount × duration).
    /// Falls back to an average track length when MusicKit returns a nil duration
    /// (common for library-only songs without catalog enrichment).
    func fetchTotalListeningTime() async throws -> TimeInterval {
        let averageTrackSeconds: TimeInterval = 210
        let songs = try await fetchLibrarySongs()

        var total = songs.reduce(TimeInterval(0)) { acc, song in
            let plays = Double(song.playCount ?? 0)
            guard plays > 0 else { return acc }
            let duration = song.duration ?? averageTrackSeconds
            return acc + plays * duration
        }

        // Fallback: iCloud play-count sync can lag for hours after a fresh listen.
        // When the library reports no plays yet, estimate from recently played history.
        if total == 0 {
            let recent = try await fetchRecentHistory(limit: 25)
            total = recent.reduce(TimeInterval(0)) { acc, song in
                acc + (song.duration ?? averageTrackSeconds)
            }
        }

        #if DEBUG
        let played = songs.filter { ($0.playCount ?? 0) > 0 }
        let missingDuration = played.filter { $0.duration == nil }.count
        print("⏱ Listening time: \(Int(total))s | played=\(played.count) | missing duration=\(missingDuration)")
        #endif

        return total
    }

    // MARK: - Recent History

    func fetchRecentHistory(limit: Int = 10) async throws -> [Song] {
        var request = MusicRecentlyPlayedRequest<Song>()
        request.limit = limit
        let response = try await request.response()
        return Array(response.items)
    }

    // MARK: - Private

    /// Fetches library songs used for aggregation, paginating until `maxCount` or exhaustion.
    /// MusicKit caps `MusicLibraryRequest.limit` at 100 per batch — pagination is required
    /// to aggregate accurately over a large library.
    private func fetchLibrarySongs(maxCount: Int = 2000) async throws -> [Song] {
        var request = MusicLibraryRequest<Song>()
        request.sort(by: \.playCount, ascending: false)
        request.limit = 100

        var current: MusicItemCollection<Song>? = try await request.response().items
        var all: [Song] = []

        while let batch = current, !batch.isEmpty, all.count < maxCount {
            all.append(contentsOf: batch)
            current = batch.hasNextBatch ? try await batch.nextBatch(limit: 100) : nil
        }
        return all
    }
}
