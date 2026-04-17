//
//  Config.swift
//  Jamly
//
//  Created by REVERSS on 20/03/2026.
//

enum Config {
#if DEBUG
    static let baseURL = "http://10.41.176.126:80"
#else
    static let baseURL = "https://api.jamly.app"
#endif
}

