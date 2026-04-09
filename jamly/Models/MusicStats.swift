//
//  MusicStats.swift
//  jamly
//

import MusicKit

struct ArtistStat: Identifiable {
    let id: String
    let name: String
    let playCount: Int
    let artwork: Artwork?
}

struct AlbumStat: Identifiable {
    let id: String
    let title: String
    let artistName: String
    let playCount: Int
    let artwork: Artwork?
}

struct GenreStat: Identifiable {
    let id: String
    let name: String
    let playCount: Int
}
