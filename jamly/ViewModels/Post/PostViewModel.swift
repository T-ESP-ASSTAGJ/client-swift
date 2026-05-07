//
//  ProfileViewModel.swift
//  jamly
//
//  Created by REVERSS on 30/12/2025.
//

import Foundation
import Combine

/// ViewModel d'un post (actions sociales et signalement).
///
/// Couvre les interactions sur un post existant : like / unlike, comptage de vues, et
/// signalement. Le chargement des posts eux-mêmes est géré par ``UserStore`` (feeds)
/// ou ``DiscoverViewModel``.
@MainActor
final class PostViewModel: ObservableObject {
    /// État simple d'une action d'écriture (like/unlike/report).
    enum VerifyState {
        case loading
        case success
        case error
    }

    @Published var state: VerifyState = .loading
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Actions

    /// Like un post côté serveur et met à jour ``state`` selon le résultat.
    ///
    /// - Parameter post: Post à liker.
    func likePost(post: Post) {
        Task {
            errorMessage = nil
            
            do {
                let response = try await PostActions.likePost(post: post)
                
                switch response.statusCode {
                case 204:
                    state = .success
                    
                case 422:
                    state = .error
                    errorMessage = "An error occurred. Please try again."
                    
                default:
                    state = .error
                    errorMessage = "An error occurred."
                }
            } catch {
                state = .error
                errorMessage = "An error occurred."
            }
        }
    }
    
    /// Retire le like précédemment posé sur un post.
    ///
    /// - Parameter post: Post à unliker.
    func unlikePost(post: Post) {
        Task {
            errorMessage = nil
            
            do {
                let response = try await PostActions.unlikePost(post: post)
                
                switch response.statusCode {
                case 204:
                    state = .success
                    
                case 422:
                    state = .error
                    errorMessage = "An error occurred. Please try again."
                    
                default:
                    state = .error
                    errorMessage = "An error occurred."
                }
            } catch {
                state = .error
                errorMessage = "An error occurred."
            }
        }
    }
    
    /// Incrémente le compteur de vues d'un post côté serveur.
    ///
    /// À appeler lorsqu'un post devient visible à l'écran (par ex. via `.onAppear`).
    ///
    /// - Parameter post: Post visualisé.
    func viewPost(post: Post) {
        Task {
            errorMessage = nil

            do {
                let response = try await PostActions.viewPost(post: post)

                switch response.statusCode {
                case 200:
                    state = .success

                case 422:
                    state = .error
                    errorMessage = "An error occurred. Please try again."

                default:
                    state = .error
                    errorMessage = "An error occurred."
                }
            } catch {
                state = .error
                errorMessage = "An error occurred."
            }
        }
    }

    // MARK: - Delete

    func deletePost(postId: Int, onSuccess: @escaping () -> Void) {
        Task {
            do {
                _ = try await PostActions.deletePost(postId: postId)
                onSuccess()
            } catch {
                errorMessage = "Failed to delete post. Please try again."
            }
        }
    }

    // MARK: - Report

    /// Liste des motifs de signalement disponibles, chargée à la demande.
    @Published var reportReasons: [ReportReason] = []
    @Published var isReportLoading: Bool = false
    /// `true` une fois qu'un signalement a abouti, utilisé pour fermer la modale et afficher
    /// une confirmation.
    @Published var reportSuccess: Bool = false
    /// `true` quand le serveur indique qu'un signalement existe déjà pour ce post par cet
    /// utilisateur (statut `422`).
    @Published var alreadyReported: Bool = false
    @Published var reportError: String?

    /// Charge la liste des motifs de signalement à présenter dans la modale de report.
    func fetchReportReasons() {
        Task {
            do {
                let response = try await PostActions.fetchReportReasons()
                reportReasons = response.value
            } catch {
                print("❌ Failed to fetch report reasons: \(error)")
            }
        }
    }

    /// Signale un post auprès du serveur.
    ///
    /// Distingue deux cas d'erreur courants :
    /// - `422` → ``alreadyReported`` passe à `true` (l'utilisateur a déjà signalé ce post),
    /// - autres erreurs → ``reportError`` est renseigné avec un message générique.
    ///
    /// - Parameters:
    ///   - postId: Identifiant du post à signaler.
    ///   - reason: Clé du motif sélectionné.
    ///   - message: Commentaire libre saisi par l'utilisateur.
    func reportPost(postId: Int, reason: String, message: String) async {
        isReportLoading = true
        reportError = nil
        defer { isReportLoading = false }

        do {
            _ = try await PostActions.reportPost(postId: postId, reason: reason, message: message)
            reportSuccess = true
        } catch APIError.serverError(statusCode: 422, _) {
            alreadyReported = true
        } catch {
            reportError = "An error occurred. Please try again."
        }
    }
}




