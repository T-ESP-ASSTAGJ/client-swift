//
//  JamPost.swift
//  jamly
//
//  Created by REVERSS on 05/12/2025.
//


import Foundation

struct JamPost: Identifiable {
    let id = UUID()
    let authorName: String
    let authorAvatarName: String
    let location: String
    let timeString: String
    let coverImageName: String
    let listenerAvatarName: String
    let title: String
    let subtitle: String
    let year: String
    let likes: Int
    let comments: Int
    
    static let mock: [JamPost] = [
        .init(
            authorName: "AlineA",
            authorAvatarName: "avatar1",
            location: "France, Paris",
            timeString: "Hier, 13:28",
            coverImageName:"https://images.unsplash.com/photo-1511379938547-c1f69419868d?fm=jpg",
            listenerAvatarName: "https://images.unsplash.com/photo-1757383747743-03d28fe8004a?fm=jpg",
            title: "BOOBA",
            subtitle: "A.C. Milan",
            year: "2012",
            likes: 13,
            comments: 4
        ),
        .init(
            authorName: "Leilaaa",
            authorAvatarName: "avatar1",
            location: "France, Strasbourg",
            timeString: "12/05/2025, 13:28",
            coverImageName:"https://images.unsplash.com/photo-1511379938547-c1f69419868d?fm=jpg",
            listenerAvatarName: "https://images.unsplash.com/photo-1757383747743-03d28fe8004a?fm=jpg",
            title: "Another Track",
            subtitle: "Artist Name",
            year: "2024",
            likes: 8,
            comments: 2
        ),
        .init(
            authorName: "User X",
            authorAvatarName: "avatar1",
            location: "France, Lyon",
            timeString: "10/05/2025, 18:02",
            coverImageName:"https://images.unsplash.com/photo-1511379938547-c1f69419868d?fm=jpg",
            listenerAvatarName: "https://images.unsplash.com/photo-1757383747743-03d28fe8004a?fm=jpg",
            title: "Third Jam",
            subtitle: "Feat. Someone",
            year: "2023",
            likes: 21,
            comments: 6
        )
    ]
}
