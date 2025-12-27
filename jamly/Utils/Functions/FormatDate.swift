//
//  FormatDate.swift
//  jamly
//
//  Created by REVERSS on 26/12/2025.
//

import Foundation

func formatRelativeTime(_ dateString: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    
    guard let date = formatter.date(from: dateString) else {
        return dateString
    }
    
    let calendar = Calendar.current
    let now = Date()
    let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
    
    if let day = components.day, day > 0 {
        return "\(day)j"
    } else if let hour = components.hour, hour > 0 {
        return "\(hour)h"
    } else if let minute = components.minute, minute > 0 {
        return "\(minute)min"
    } else {
        return "maintenant"
    }
}
