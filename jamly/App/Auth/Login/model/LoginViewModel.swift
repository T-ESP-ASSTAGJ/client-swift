import Foundation
import Combine

@MainActor
final class LoginViewModel: ObservableObject {
    enum VerifyState {
        case idle
        case loading
        case success
        case emailNotFound
        case invalidCode
        case error
    }
    
    @Published var state: VerifyState = .idle
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    private let secureStore: SecureStore
    
    init(secureStore: SecureStore? = nil) {
        self.secureStore = secureStore ?? .shared
    }
    
    // MARK: - Actions
    
    func request(email: String) {
        Task {
            isLoading = true
            errorMessage = nil
            state = .loading
            
            do {
                let response = try await AuthActions.request(email: email)
                
                switch response.statusCode {
                case 201:
                    state = .success
                    
                case 400:
                    state = .invalidCode
                    errorMessage = "Requête invalide."
                    
                case 404:
                    state = .emailNotFound
                    errorMessage = "Email non trouvé."
                    
                default:
                    state = .error
                    errorMessage = "Une erreur est survenue."
                }
            } catch {
                state = .error
                errorMessage = "Une erreur est survenue."
            }
            
            isLoading = false
        }
    }
    
    func verify(email: String, code: String) {
        Task {
            isLoading = true
            errorMessage = nil
            state = .loading
            
            do {
                let response = try await AuthActions.verify(email: email, code: code)
                
                switch response.statusCode {
                case 201:
                    let token = response.value.token
                    secureStore.save(token: token, key: "token")
                    state = .success
                    
                case 400:
                    state = .invalidCode
                    errorMessage = "Code invalide."
                    
                case 404:
                    state = .emailNotFound
                    errorMessage = "Email non trouvé."
                    
                default:
                    state = .error
                    errorMessage = "Une erreur est survenue."
                }
            } catch let error as APIError {
                switch error {
                case .unauthorized:
                    state = .invalidCode
                    errorMessage = "Code de vérification incorrect."
                default:
                    state = .error
                    errorMessage = "Une erreur est survenue."
                }
            } catch {
                state = .error
                errorMessage = "Une erreur est survenue."
            }
            
            isLoading = false
        }
    }
}

