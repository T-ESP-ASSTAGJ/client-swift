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

private func calculateRelativeTime(from date: Date) -> String {
    let calendar = Calendar.current
    let now = Date()
    let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
    
    if let day = components.day, day > 0 {
        return "\(day)d ago"
    } else if let hour = components.hour, hour > 0 {
        return "\(hour)h ago"
    } else if let minute = components.minute, minute > 0 {
        return "\(minute)min ago"
    } else {
        return "Now"
    }
}
