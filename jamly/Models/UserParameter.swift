// UserParameter.swift
// jamly

import Foundation
import SwiftUI

enum VisibilityOption: String, Codable, CaseIterable {
    case `public` = "public"
    case friends = "friends"
    case `private` = "private"

    var label: String {
        switch self {
        case .public: return "Public"
        case .friends: return "Friends"
        case .private: return "Private"
        }
    }

    var icon: String {
        switch self {
        case .public: return "globe"
        case .friends: return "person.2"
        case .private: return "lock"
        }
    }

    var color: Color {
        switch self {
        case .public: return .blue
        case .friends: return .green
        case .private: return .red
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
