//
//  ProfileHeaderView.swift
//  jamly
//

import SwiftUI

struct ProfileHeaderView: View {
    let user: User?
    let isOwnProfile: Bool
    @Binding var selectedFollowView: FollowViews?

    @State private var showFullScreenAvatar = false

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
                    .onTapGesture { showFullScreenAvatar = true }

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
        .fullScreenCover(isPresented: $showFullScreenAvatar) {
            FullScreenImageViewer(
                url: URL(string: fullImageURL(user?.displayProfilePictureURL ?? Config.defaultProfilePictureURL))
            )
        }
    }

    private var profilePicture: some View {
        // `displayProfilePictureURL` renvoie la photo de l'utilisateur ou l'avatar
        // par défaut ; `fullImageURL` préfixe `Config.baseURL` si le chemin est relatif.
        let pictureURL = fullImageURL(user?.displayProfilePictureURL ?? Config.defaultProfilePictureURL)

        return CachedAsyncImage(
            url: URL(string: pictureURL),
            targetSize: CGSize(width: 85, height: 85)
        ) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .overlay { ProgressView() }
        }
        .frame(width: 85, height: 85)
        .clipShape(Circle())
    }

    /// Préfixe l'URL avec ``Config/baseURL`` quand le backend renvoie un chemin relatif,
    /// comme le fait `PostCard` pour son image principale.
    private func fullImageURL(_ urlString: String) -> String {
        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
            return urlString
        }
        return Config.baseURL + urlString
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

// MARK: - Full Screen Image Viewer

/// Affiche une image en plein écran avec zoom (pincement / double-tap) et fermeture par
/// glissement vers le bas ou bouton de fermeture. Utilisé pour agrandir une photo de profil.
struct FullScreenImageViewer: View {
    let url: URL?
    @Environment(\.dismiss) private var dismiss

    @State private var scale: CGFloat = 1
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black
                .opacity(backgroundOpacity)
                .ignoresSafeArea()

            CachedAsyncImage(
                url: url,
                targetSize: CGSize(width: 1000, height: 1000)
            ) {
                ProgressView().tint(.white)
            }
            .scaledToFit()
            .scaleEffect(scale)
            .offset(dragOffset)
            .gesture(magnification)
            .gesture(dragToDismiss)
            .onTapGesture(count: 2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    scale = scale > 1 ? 1 : 2.5
                }
            }

            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .padding(.top, 12)
                    .padding(.trailing, 16)
                }
                Spacer()
            }
        }
        .statusBarHidden()
    }

    /// Le fond s'éclaircit à mesure qu'on glisse l'image pour la fermer.
    private var backgroundOpacity: Double {
        max(0, 1 - Double(abs(dragOffset.height)) / 400)
    }

    private var magnification: some Gesture {
        MagnificationGesture()
            .onChanged { scale = max(1, $0) }
            .onEnded { _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    scale = max(1, min(scale, 4))
                }
            }
    }

    /// Glissement vertical pour fermer (actif uniquement quand l'image n'est pas zoomée).
    private var dragToDismiss: some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale <= 1 else { return }
                dragOffset = value.translation
            }
            .onEnded { value in
                guard scale <= 1 else { return }
                if abs(value.translation.height) > 120 {
                    dismiss()
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        dragOffset = .zero
                    }
                }
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
