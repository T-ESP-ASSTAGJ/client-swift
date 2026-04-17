//
//  Report.swift
//  jamly
//
//  Created by REVERSS on 16/04/2026.
//

struct ReportReason: Codable {
    let key: String
    let label: String
}

struct ReportBody: Encodable {
    let entityClass: String = "App\\Entity\\Post"
    let entityId: Int
    let reason: String
    let message: String
}
