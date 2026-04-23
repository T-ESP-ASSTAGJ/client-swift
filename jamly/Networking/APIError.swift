//
//  APIError.swift
//  jamly
//
//  Created by REVERSS on 06/12/2025.
//


import Foundation

enum APIError: Error {
    case invalidURL
    case decodingFailed
    case unauthorized
    case serverError(statusCode: Int, data: Data?)
    case networkError(Error)
}
extension APIError: LocalizedError {
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
    
    /// Determines if the error might indicate a partial success
    var isPossiblePartialSuccess: Bool {
        if case .serverError(let statusCode, _) = self,
           statusCode == 500 {
            return true
        }
        return false
    }
}

