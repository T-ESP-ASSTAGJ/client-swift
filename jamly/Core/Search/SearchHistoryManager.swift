//
//  SearchHistoryManager.swift
//  jamly
//
//  Created by Alexandre Vandenbulcke on 30/12/2025.
//

import Foundation

/// Gestionnaire de l'historique de recherche persisté localement dans `UserDefaults`.
///
/// L'historique est plafonné à 20 entrées et déduplique automatiquement : rechercher
/// à nouveau une requête existante la fait remonter en tête.
class SearchHistoryManager {
    /// Instance partagée à utiliser depuis les ViewModels de recherche.
    static let shared = SearchHistoryManager()

    private let key = "searchHistory"
    private let maxHistoryItems = 20

    private init() {}

    /// Charge l'historique de recherche depuis `UserDefaults`.
    ///
    /// - Returns: Les requêtes ordonnées de la plus récente à la plus ancienne.
    ///   Tableau vide si aucune recherche n'a encore été enregistrée.
    func loadHistory() -> [String] {
        UserDefaults.standard.stringArray(forKey: key) ?? []
    }

    /// Ajoute une requête à l'historique en tête de liste.
    ///
    /// Si la requête est déjà présente, elle est retirée puis réinsérée en tête. L'historique
    /// est tronqué à 20 entrées maximum.
    ///
    /// - Parameter query: Requête à enregistrer (non vide).
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

    /// Retire une requête spécifique de l'historique.
    ///
    /// - Parameter query: Requête à supprimer. L'opération est silencieuse si elle n'existe pas.
    func removeFromHistory(_ query: String) {
        var history = loadHistory()
        history.removeAll { $0 == query }
        UserDefaults.standard.set(history, forKey: key)
    }

    /// Vide entièrement l'historique de recherche.
    func clearHistory() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
