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
