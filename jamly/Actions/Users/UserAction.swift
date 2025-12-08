//
//  User.swift
//  jamly
//
//  Created by REVERSS on 06/12/2025.
//


// Actions/UserActions.swift
import Foundation

enum UserActions {
    static func fetchMe() async throws -> APIResponse<User> {
        let response = try await APIClient.shared.request(
            "/users/me",
            method: .get,
            responseType: User.self
        )
        
        print("😁 /ME \(response.value)")
        
        return response
    }
}
