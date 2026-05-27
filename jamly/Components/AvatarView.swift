import SwiftUI

struct AvatarView: View {
    let profilePicture: String?
    let size: CGFloat

    var body: some View {
        let urlString = User.displayProfilePictureURL(from: profilePicture)

        CachedAsyncImage(
            url: URL(string: urlString),
            targetSize: CGSize(width: size, height: size)
        ) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .overlay {
                    Image(systemName: "person.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: size * 0.4))
                }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: Action?

    struct Action {
        let label: String
        let icon: String?
        let handler: () -> Void
    }

    init(icon: String, title: String, subtitle: String, action: Action? = nil) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }

    private var gradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.6, green: 0.4, blue: 0.9),
                Color(red: 0.8, green: 0.4, blue: 0.7)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 92, height: 92)
                    .overlay {
                        Circle().stroke(.white.opacity(0.12), lineWidth: 1)
                    }
                Image(systemName: icon)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(gradient)
            }

            VStack(spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if let action {
                Button(action: action.handler) {
                    HStack(spacing: 8) {
                        if let icon = action.icon {
                            Image(systemName: icon)
                                .font(.footnote.weight(.semibold))
                        }
                        Text(action.label)
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(gradient))
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }
}

struct GroupAvatarView: View {
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: "person.3.fill")
                    .foregroundColor(.gray)
                    .font(.system(size: size * 0.3))
            }
    }
}
