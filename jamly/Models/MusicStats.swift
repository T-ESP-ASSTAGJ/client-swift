//
//  MusicStats.swift
//  jamly
//

import MusicKit

/// Statistique d'écoute agrégée pour un artiste donné.
///
/// Produite par ``MusicStatsService`` à partir des historiques Apple Music et
/// affichée dans la section « Top artistes » du profil utilisateur.
struct ArtistStat: Identifiable {
    let id: String
    let name: String
    let playCount: Int
    /// Pochette fournie par MusicKit ; peut être absente pour certains artistes peu référencés.
    let artwork: Artwork?
}

/// Statistique d'écoute agrégée pour un album donné.
struct AlbumStat: Identifiable {
    let id: String
    let title: String
    let artistName: String
    let playCount: Int
    /// Pochette de l'album fournie par MusicKit.
    let artwork: Artwork?
}

/// Statistique d'écoute agrégée pour un genre musical.
///
/// Le genre n'a pas d'artwork associé dans MusicKit, d'où l'absence du champ.
struct GenreStat: Identifiable {
    let id: String
    let name: String
    let playCount: Int
}
