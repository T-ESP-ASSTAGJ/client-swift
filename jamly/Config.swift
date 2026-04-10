//
//  Config.swift
//  Jamly
//
//  Created by REVERSS on 20/03/2026.
//

enum Config {
#if DEBUG
    static let baseURL = "http://10.68.253.64:80"
#else
    static let baseURL = "https://api.jamly.app"
#endif
}

