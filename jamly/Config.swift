//
//  Config.swift
//  Jamly
//
//  Created by REVERSS on 20/03/2026.
//

enum Config {
#if DEBUG
    static let baseURL = "http://10.68.245.113:80"
#else
    static let baseURL = "https://api.jamly.eu"
#endif

    static let appleMusicHost = "music.apple.com"
    static let appleMusicBaseURL = "https://music.apple.com/"
    static let appleMusicPlaylistPath = "/playlist/"

    /// Endpoint public iTunes Lookup, utilisé pour récupérer les previews 30 s
    /// sans autorisation Apple Music.
    static let itunesLookupBaseURL = "https://itunes.apple.com/lookup"

    static let defaultProfilePictureURL = "https://www.gravatar.com/avatar/?d=mp&s=300"

    // API endpoint base paths
    static let usersPath = "/users"
    static let postsPath = "/posts"
    static let messagesPath = "/messages"
    static let conversationsPath = "/conversations"
    static let sharedPostPath = "/post/"
}

