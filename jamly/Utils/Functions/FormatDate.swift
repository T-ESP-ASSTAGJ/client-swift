//
//  FormatDate.swift
//  jamly
//
//  Created by REVERSS on 26/12/2025.
//

import Foundation

func formatRelativeTime(_ dateString: String) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    
    guard let date = formatter.date(from: dateString) else {
        // Fallback: essayer sans les fractions de secondes
        formatter.formatOptions = [.withInternetDateTime]
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        return calculateRelativeTime(from: date)
    }
    
    return calculateRelativeTime(from: date)
}

private let shortDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US")
    f.dateFormat = "d MMMM"
    return f
}()

private let fullDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US")
    f.dateFormat = "d MMMM yyyy"
    return f
}()

private func calculateRelativeTime(from date: Date) -> String {
    let calendar = Calendar.current
    let now = Date()
    let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)

    // À partir d'un jour : affiche la date de publication au lieu de "Xd ago".
    if let day = components.day, day > 0 {
        if day > 365 {
            return fullDateFormatter.string(from: date) // ex: 30 January 2025
        }
        return shortDateFormatter.string(from: date)     // ex: 30 January
    } else if let hour = components.hour, hour > 0 {
        return "\(hour)h ago"
    } else if let minute = components.minute, minute > 0 {
        return "\(minute)min ago"
    } else {
        return "Now"
    }
}
