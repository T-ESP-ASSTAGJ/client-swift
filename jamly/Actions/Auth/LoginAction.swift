//
//  AuthLoginResponse.swift
//  jamly
//
//  Created by REVERSS on 06/12/2025.
//


struct AuthRequestResponse: Decodable {
    let message: String
}

struct AuthVerifyResponse: Decodable {
    let message: String
    let token: String
}

enum AuthActions {
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
