import SwiftUI

enum ProfileTab {
    case posts, likes, bookmarks
}

enum FollowViews: Identifiable {
    var id: String { String(describing: self) }
    case following, followers
}

struct ProfileView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var userStore: UserStore
    @EnvironmentObject var musicManager: MusicManager
    
    @State private var selectedTab: ProfileTab = .posts
    @State private var selectedFollowView: FollowViews? = nil
    @State private var showMusicPlaylists = false
    @State private var tabsOffset: CGFloat = 0
    
    let photos = [
        ("photo1", "661K"),
        ("photo2", "97K"),
        ("photo3", "808K"),
        ("photo4", "373K"),
        ("photo5", "581K"),
        ("photo6", "768K"),
        ("photo7", "640K"),
        ("photo8", "62K"),
        ("photo9", "916K"),
        ("photo10", "276K"),
        ("photo11", "26K"),
        ("photo12", "2K"),
    ]
    
    let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 0) {
                    // Header (photo de profil et infos)
                    headerSection
                    
                    // Tabs avec GeometryReader pour détecter la position
                    GeometryReader { geometry in
                        let minY = geometry.frame(in: .global).minY - 110
                        
                        VStack(spacing: 0) {
                            HStack(spacing: 0) {
                                TabButton(
                                    icon: "square.grid.3x3.fill",
                                    isSelected: selectedTab == .posts
                                ) {
                                    selectedTab = .posts
                                }
                                
                                TabButton(
                                    icon: "heart.fill",
                                    isSelected: selectedTab == .likes
                                ) {
                                    selectedTab = .likes
                                }
                                
                                TabButton(
                                    icon: "bookmark.fill",
                                    isSelected: selectedTab == .bookmarks
                                ) {
                                    selectedTab = .bookmarks
                                }
                            }
                            .background(Color.black) // ✅ Fond noir opaque
                        }
                        .frame(maxWidth: .infinity) // ✅ Prend toute la largeur
                        .background(Color.black) // ✅ Double fond noir pour être sûr
                        .offset(y: minY < 0 ? -minY : 0)
                        .zIndex(10) // ✅ Met les tabs au-dessus de tout
                    }
                    .frame(height: 50)
                    .zIndex(10) // ✅ GeometryReader aussi au-dessus
                    
                    // Grille de photos
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(0..<photos.count, id: \.self) { index in
                            ZStack(alignment: .bottomLeading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .aspectRatio(1, contentMode: .fill)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "eye.fill")
                                        .font(.caption)
                                    Text(photos[index].1)
                                        .font(.caption)
                                        .bold()
                                }
                                .foregroundColor(.white)
                                .padding(8)
                            }
                            .clipped()
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
            .coordinateSpace(name: "scroll")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {}) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        showMusicPlaylists = true
                    } label: {
                        Image(systemName: "music.note.square.stack.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                    }.padding(.trailing, 3)
                    
                    Button {
                        authManager.logout()
                    } label: {
                        Image(systemName: "door.left.hand.open")
                            .font(.system(size: 15))
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationDestination(isPresented: $showMusicPlaylists) {
                MusicPlaylistsView()
                    .environmentObject(musicManager)
            }
            .navigationDestination(item: $selectedFollowView) { view in
                switch view {
                case .followers:
                    FollowersView()
                case .following:
                    FollowingView()
                }
            }
            
            VStack {
                ZStack {
                    // Contenu de ta barre
                }
                .frame(maxWidth: .infinity)
                .background(.black)
                
                Spacer() // Pour pousser la barre en haut
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack() {
                ZStack {
                    if let user = userStore.user, let profilePicture = user.profilePicture {
                        AsyncImage(url: URL(string: profilePicture)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 85, height: 85)
                                .clipShape(Circle())
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 85, height: 85)
                                .overlay {
                                    ProgressView()
                                }
                        }
                    } else {
                        // ✅ Pas d'user OU pas de photo
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            .frame(width: 85, height: 85)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 35))
                                    .foregroundColor(.gray)
                            }
                    }
                }
                .padding(.vertical)
                .padding(.horizontal, 7)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(userStore.user?.username ?? "")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("@\(userStore.user?.username ?? "")")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            HStack(spacing: 20) {
                Button {
                    selectedFollowView = .following
                } label: {
                    StatView(number: "441", label: "Followed")
                }
                
                VStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 1, height: 25)
                
                Button {
                    selectedFollowView = .followers
                } label: {
                    StatView(number: "164,6K", label: "Followers")
                }
                
                VStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 1, height: 25)
                
                StatView(number: "10,6M", label: "Likes")
            }
            .padding(.vertical, 0)
            .padding(.horizontal, 15)
            
            Button(action: {}) {
                HStack {
                    Image(systemName: "pencil")
                    Text("Edit Profile")
                }
                .foregroundColor(.white)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
        }
        .padding(.bottom, 24)
        .background(Color.black)
    }
}

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
                .fontWeight(.regular)
                .foregroundColor(.gray)
        }
    }
}

struct TabButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isSelected ? .white : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.black) // ✅ Changé : fond noir direct au lieu du Rectangle
                .overlay(
                    // ✅ Ajouté : overlay pour l'effet de sélection
                    Rectangle()
                        .fill(isSelected ? Color.white.opacity(0.1) : Color.clear)
                )
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(AuthManager(userStore: UserStore()))
            .environmentObject(UserStore())
            .preferredColorScheme(.dark)
    }
}
