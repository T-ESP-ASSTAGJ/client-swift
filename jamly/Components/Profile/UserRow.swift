import SwiftUI

// Protocol pour permettre l'utilisation avec différents types d'utilisateurs
protocol UserRowRepresentable {
    var id: Int { get }
    var username: String { get }
    var profilePicture: String { get }
}

// Conformance pour FollowerUser
extension FollowerUser: UserRowRepresentable {}

// Conformance pour FollowingUser
extension FollowingUser: UserRowRepresentable {}

struct UserRow<User: UserRowRepresentable>: View {
    let user: User
    let isFollowing: Bool
    let showFollowBack: Bool // Nouveau paramètre pour déterminer si on affiche "Follow back"
    var showFollowButton: Bool = true // Paramètre pour afficher/cacher le bouton
    let onToggleFollow: () async -> Void

    
    var body: some View {
        HStack(spacing: 8) {
            // Image
            HStack(spacing: 15) {
                AsyncImage(url: URL(string: user.profilePicture)) { phase in
                    Group {
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .overlay(
                                    phase.error != nil ?
                                    Image(systemName: "person.fill").foregroundColor(.gray) as! ProgressView<EmptyView, EmptyView> :
                                        ProgressView()
                                )
                        }
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                }

                // Infos
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.username)
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            Spacer()

            // Afficher le bouton uniquement si showFollowButton est true
            if showFollowButton {
                Button {
                    Task {
                        await onToggleFollow()
                    }
                } label: {
                    Text(buttonText)
                }
                .buttonStyle(.glass)
            }
        }
        .frame(height: 40)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 4, leading: 15, bottom: 20, trailing: 15))
        .scrollContentBackground(.hidden)
        .listStyle(.plain)
    }
    
    // Logique pour déterminer le texte du bouton
    private var buttonText: String {
        if isFollowing {
            return "Unfollow"
        } else {
            return showFollowBack ? "Follow back" : "Follow"
        }
    }
}
