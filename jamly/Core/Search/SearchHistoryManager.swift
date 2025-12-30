//
//  SearchHistoryManager.swift
//  jamly
//
//  Created by Alexandre Vandenbulcke on 30/12/2025.
//

import Foundation

/// Manager for persisting search history using UserDefaults
class SearchHistoryManager {
    static let shared = SearchHistoryManager()
    
    private let key = "searchHistory"
    private let maxHistoryItems = 20
    
    private init() {}
    
    /// Load search history from UserDefaults
    func loadHistory() -> [String] {
        UserDefaults.standard.stringArray(forKey: key) ?? []
    }
    
    /// Save a search query to history
    func addToHistory(_ query: String) {
        var history = loadHistory()
        
        // Remove if already exists to avoid duplicates
        history.removeAll { $0 == query }
        
        // Insert at the beginning
        history.insert(query, at: 0)
        
        // Limit to max items
        if history.count > maxHistoryItems {
            history = Array(history.prefix(maxHistoryItems))
        }
        
        UserDefaults.standard.set(history, forKey: key)
    }
    
    /// Remove a specific query from history
    func removeFromHistory(_ query: String) {
        var history = loadHistory()
        history.removeAll { $0 == query }
        UserDefaults.standard.set(history, forKey: key)
    }
    
    /// Clear all search history
    func clearHistory() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
