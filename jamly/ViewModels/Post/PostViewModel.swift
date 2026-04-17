//
//  ProfileViewModel.swift
//  jamly
//
//  Created by REVERSS on 30/12/2025.
//

import Foundation
import Combine

@MainActor
final class PostViewModel: ObservableObject {
    enum VerifyState {
        case loading
        case success
        case error
    }
    
    @Published var state: VerifyState = .loading
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Actions
    
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

    // MARK: - Report

    @Published var reportReasons: [ReportReason] = []
    @Published var isReportLoading: Bool = false
    @Published var reportSuccess: Bool = false
    @Published var alreadyReported: Bool = false
    @Published var reportError: String?

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




