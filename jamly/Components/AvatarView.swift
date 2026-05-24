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
