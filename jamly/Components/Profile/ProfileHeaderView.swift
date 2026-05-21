//
//  ProfileHeaderView.swift
//  jamly
//

import SwiftUI

struct ProfileHeaderView: View {
    let user: User?
    let isOwnProfile: Bool
    @Binding var selectedFollowView: FollowViews?

    private var isFollowingVisible: Bool {
        isOwnProfile || (user?.parameters?.followingVisibility ?? .publicVisibility) == .publicVisibility
    }

    private var isFollowersVisible: Bool {
        isOwnProfile || (user?.parameters?.followersVisibility ?? .publicVisibility) == .publicVisibility
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                profilePicture
                    .padding(.vertical)
                    .padding(.horizontal, 7)

                userInfo

                Spacer()
            }

            HStack(spacing: 20) {
                Button { selectedFollowView = .following } label: {
                    StatView(number: formatNumber(user?.followingCount ?? 0), label: "Following")
                }

                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 25)

                Button { selectedFollowView = .followers } label: {
                    StatView(number: formatNumber(user?.followersCount ?? 0), label: "Followers")
                }
            }
            .padding(.horizontal, 15)
        }
        .padding(.bottom, 24)
    }

    private var profilePicture: some View {
        let pictureURL = user?.displayProfilePictureURL ?? Config.defaultProfilePictureURL
        return AsyncImage(url: URL(string: pictureURL)) { image in
            image
                .resizable()
                .scaledToFill()
                .frame(width: 85, height: 85)
                .clipShape(Circle())
        } placeholder: {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 85, height: 85)
                .overlay { ProgressView() }
        }
    }

    private var userInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(user?.username ?? "")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("@\(user?.username ?? "")")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Stat View

struct StatView: View {
    let number: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(number)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(label)
                .font(.footnote)
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Helpers

func formatNumber(_ number: Int) -> String {
    switch number {
    case 0..<1_000:
        return "\(number)"
    case 1_000..<1_000_000:
        return String(format: "%.1fK", Double(number) / 1_000).replacingOccurrences(of: ".0", with: "")
    default:
        return String(format: "%.1fM", Double(number) / 1_000_000).replacingOccurrences(of: ".0", with: "")
    }
}
