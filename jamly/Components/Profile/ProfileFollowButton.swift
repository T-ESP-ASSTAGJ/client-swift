//
//  ProfileFollowButton.swift
//  jamly
//

import SwiftUI

struct ProfileFollowButton: View {
    let isFollowing: Bool
    let onFollow: () -> Void
    let onUnfollow: () -> Void

    var body: some View {
        if isFollowing {
            Button(action: onUnfollow) {
                Text("Unfollow")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(8)
            }
        } else {
            Button(action: onFollow) {
                Text("Follow")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(8)
            }
        }
    }
}
