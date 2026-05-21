// UserParameter.swift
// jamly

import Foundation
import SwiftUI

enum VisibilityOption: String, Codable, CaseIterable {
    case publicVisibility = "public"
    case friends = "friends"
    case privateVisibility = "private"

    var label: String {
        switch self {
        case .publicVisibility: return "Public"
        case .friends: return "Friends"
        case .privateVisibility: return "Private"
        }
    }

    var icon: String {
        switch self {
        case .publicVisibility: return "globe"
        case .friends: return "person.2"
        case .privateVisibility: return "lock"
        }
    }

    var color: Color {
        switch self {
        case .publicVisibility: return .blue
        case .friends: return .green
        case .privateVisibility: return .red
        }
    }
}

struct UserParameter: Codable {
    var followersVisibility: VisibilityOption
    var followingVisibility: VisibilityOption
    var statsVisibility: VisibilityOption
    var playlistVisibility: VisibilityOption
    var likesVisibility: VisibilityOption
    var notifNewFollower: VisibilityOption
    var notifNewLike: VisibilityOption
    var notifNewComment: VisibilityOption
    var notifNewMessage: VisibilityOption
}
