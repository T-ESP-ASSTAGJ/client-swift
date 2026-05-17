//
//  AuthLogin.swift
//  jamly
//
//  Created by REVERSS on 06/12/2025.
//


/// Réponse de l'endpoint `/auth/request` ; ne contient qu'un message de confirmation
/// indiquant qu'un code a été envoyé par email.
struct AuthRequestResponse: Decodable {
    let message: String
}

/// Réponse de l'endpoint `/auth/verify` ; contient le JWT à stocker en cas de succès.
struct AuthVerifyResponse: Decodable {
    let message: String
    let token: String
}

/// Actions liées à l'authentification par email/code OTP.
///
/// L'authentification se fait en deux temps :
/// 1. ``request(email:)`` envoie un code à 6 chiffres sur l'adresse fournie,
/// 2. ``verify(email:code:)`` échange le code contre un JWT.
enum AuthActions {
    /// Déclenche l'envoi d'un code de connexion à l'adresse email fournie.
    ///
    /// - Parameter email: Adresse email du compte cible.
    /// - Returns: La réponse de l'API confirmant l'envoi.
    /// - Throws: ``APIError`` en cas d'échec réseau ou serveur.
    static func request(email: String) async throws -> APIResponse<AuthRequestResponse> {
        let body = [
            "email": email,
        ]

        return try await APIClient.shared.request(
            "/auth/request",
            method: .post,
            body: body,
            responseType: AuthRequestResponse.self
        )
    }

    /// Vérifie un code OTP et retourne le JWT associé.
    ///
    /// - Parameters:
    ///   - email: Adresse email utilisée à l'étape ``request(email:)``.
    ///   - code: Code à 6 chiffres saisi par l'utilisateur.
    /// - Returns: Le JWT et un message de confirmation.
    /// - Throws: ``APIError`` ; un statut `400` indique généralement un code invalide ou expiré.
    static func verify(email: String, code: String) async throws -> APIResponse<AuthVerifyResponse> {
        let body = [
            "email": email,
            "code": code
        ]

        return try await APIClient.shared.request(
            "/auth/verify",
            method: .post,
            body: body,
            responseType: AuthVerifyResponse.self
        )
    }
}
