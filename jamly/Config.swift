//
//  Config.swift
//  Jamly
//
//  Created by REVERSS on 20/03/2026.
//

enum Config {
    /// URL de base de l'API.
    ///
    /// En tests UI (`-UITEST`), on force l'URL release pour que les requêtes
    /// reçues par `MockURLProtocol` soient identiques à celles de production
    /// (les routes du mock sont matchées sur le path exact `/api/...`).
    static var baseURL: String {
        if CommandLine.arguments.contains("-UITEST") {
            return "https://api.jamly.eu"
        }
        #if DEBUG
        return "http://10.68.245.180:80"
        #else
        return "https://api.jamly.eu"
        #endif
    }

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

