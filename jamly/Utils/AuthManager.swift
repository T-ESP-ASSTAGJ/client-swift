//
//  AuthManager.swift
//  jamly
//
//  Created by REVERSS on 07/12/2025.
//

import Foundation
import Combine

final class AuthManager: ObservableObject {
    @Published var isAuthenticated: Bool = false {
        didSet {
            print("🔐 AuthManager.isAuthenticated changed to: \(isAuthenticated)")
        }
    }
    
    // MARK: - Dependencies
    private let userStore: UserStore
    private let secureStore: SecureStore
    private var cancellables = Set<AnyCancellable>()
    
    init(userStore: UserStore, secureStore: SecureStore = .shared) {
        self.userStore = userStore
        self.secureStore = secureStore
        
        print("🔐 AuthManager init - Checking token...")
        
        // Vérifier si un token existe déjà dans SecureStore
        if secureStore.retrieve() != nil {
            isAuthenticated = true
            print("🔐 Token found, user authenticated")
        } else {
            print("🔐 No token found")
        }
        
        // Observer les changements d'authentification du UserStore
        userStore.$isAuthenticated
            .sink { [weak self] isAuth in
                self?.isAuthenticated = isAuth
            }
            .store(in: &cancellables)
        
        // Observer les notifications d'erreur 401
        NotificationCenter.default.addObserver(
            forName: .didReceiveUnauthorized,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.logout()
        }
    }
    
    func logout() {
        print("🔐 AuthManager.logout called")
        userStore.logout()
        isAuthenticated = false
    }
    
    func login(token: String) {
        print("🔐 AuthManager.login called")
        userStore.setToken(token)
        isAuthenticated = true
    }
}
