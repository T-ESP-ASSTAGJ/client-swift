//
//  APIError.swift
//  jamly
//
//  Created by REVERSS on 06/12/2025.
//


import Foundation

/// Erreurs typées renvoyées par ``APIClient`` lors des appels à l'API Jamly.
///
/// Permet aux appelants de distinguer un problème de construction de requête,
/// une session expirée, une erreur côté serveur ou un échec réseau.
enum APIError: Error {
    /// L'URL n'a pas pu être construite (chemin ou paramètres invalides).
    case invalidURL
    /// Le corps de la réponse n'a pas pu être décodé dans le type attendu.
    case decodingFailed
    /// Le serveur a répondu `401`. Le token est supprimé et l'utilisateur doit se reconnecter.
    case unauthorized
    /// Le serveur a renvoyé un statut hors `2xx`. `data` contient éventuellement le corps brut
    /// permettant d'extraire un message d'erreur détaillé.
    case serverError(statusCode: Int, data: Data?)
    /// Échec réseau de bas niveau (timeout, pas de connexion, etc.). Encapsule l'erreur d'origine.
    case networkError(Error)
}
extension APIError: LocalizedError {
    /// Message localisé prêt à être affiché à l'utilisateur.
    ///
    /// Pour `serverError`, tente d'extraire le champ `detail` du JSON renvoyé par l'API
    /// (format API Platform). En l'absence de ce champ, retourne un message générique
    /// avec le code de statut.
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"

        case .decodingFailed:
            return "Failed to decode server response"

        case .unauthorized:
            return "Unauthorized. Please log in again."

        case .serverError(let statusCode, let data):
            // Try to parse error message from backend
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let detail = json["detail"] as? String {
                return detail
            }
            return "Server error (\(statusCode))"

        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }

    /// Indique si l'erreur peut correspondre à un succès partiel côté serveur.
    ///
    /// Utilisé pour les opérations où une `500` n'implique pas forcément un échec total
    /// (par exemple, l'écriture peut avoir réussi malgré la réponse en erreur).
    /// L'appelant peut alors choisir de rafraîchir l'état plutôt que d'afficher une erreur dure.
    var isPossiblePartialSuccess: Bool {
        if case .serverError(let statusCode, _) = self,
           statusCode == 500 {
            return true
        }
        return false
    }
}

