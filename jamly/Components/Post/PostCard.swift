//
//  JamPostCard.swift
//  jamly
//
//  Created by REVERSS on 05/12/2025.
//

import SwiftUI

struct PostCard: View {
    let post: Post
    let isCurrentPost: Bool
    @ObservedObject var musicManager: MusicManager
    
    @State private var coverUIImage: UIImage?
    @State private var avatarUIImage: UIImage?
    @State private var isSwapped = false
    @State private var showCommentsSheet: Bool = false
    
    var body: some View {
        // ✅ Utilise un ZStack pour occuper TOUTE la hauteur
        ZStack {
            VStack(spacing: 0) {
                // Header utilisateur
                HStack {
                    AsyncImage(url: URL(string: post.user.profilePicture)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 40, height: 40)
                            .overlay {
                                ProgressView()
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(post.user.username)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                        Text(post.location)
                            .font(.caption)
                            .foregroundColor(.white)
                            .opacity(0.7)
                    }
                    
                    Spacer()
                    
                    Text("23 minutes ago")
                        .font(.caption)
                        .foregroundColor(.white)
                        .opacity(0.7)
                }
                .padding(.top, 25)
                .padding(.horizontal, 15)
                .padding(.bottom, 25)
                
                // Image principale avec boutons
                ZStack(alignment: .bottom) {
                    // 🎨 IMAGE PRINCIPALE + MINIATURE
                    ZStack(alignment: .topTrailing) {
                        // IMAGE PRINCIPALE AVEC BOUTON PAUSE CENTRÉ
                        ZStack { // ← ZStack simple pour centrer le pause
                            Group {
                                if let img = isSwapped ? avatarUIImage : coverUIImage {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    Color.gray.opacity(0.2)
                                }
                            }
                            
                            // ✅ BOUTON PAUSE CENTRÉ (directement dans le même ZStack)
                            if !musicManager.isPlaying && isCurrentPost {
                                ZStack {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 36, weight: .semibold))
                                        .contentTransition(.symbolEffect(.replace))
                                        .foregroundStyle(.white.opacity(0.6))
                                        .shadow(color: .white.opacity(0.6), radius: 4, x: 0, y: 0) // Inner glow
                                        .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 4) // Drop shadow
                                }
                                .opacity(musicManager.isPlaying ? 0 : 0.8)
                                .animation(.easeInOut(duration: 0.2), value: musicManager.isPlaying)
                            }
                        }
                        .frame(width: 370, height: 420)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        
                        HStack(alignment: .top) {
                            HStack(spacing: 6) {
                                Image(systemName: "music.note")
                                    .font(.system(size: 11, weight: .semibold))
                                
                                Text("Playing")
                                    .font(.caption.weight(.medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .overlay {
                                Capsule()
                                    .stroke(.white.opacity(0.3), lineWidth: 1)
                            }
                            .padding(.top, 20)
                            .padding(.horizontal, 16)
                            .opacity(isCurrentPost && musicManager.isPlaying ? 1 : 0)
                            .animation(.easeInOut(duration: 0.2), value: musicManager.isPlaying)
                            
                            Spacer()
                            
                            // 👉 BOUTON MINIATURE DROITE
                            ZStack {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isSwapped.toggle()
                                    }
                                } label: {
                                    ZStack {
                                        if let img = isSwapped ? coverUIImage : avatarUIImage {
                                            Image(uiImage: img)
                                                .resizable()
                                                .scaledToFill()
                                        } else {
                                            Color.gray.opacity(0.2)
                                        }
                                    }
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                            .padding(.top, 20)
                            .padding(.horizontal, 16)  // ✅ Padding interne au HStack
                        }
                        .frame(width: 370)
                    }
                    .task {
                        await preloadImages()
                    }
                    
                    // ❤️ STATISTIQUES (en bas)
                    HStack(spacing: 10) {
                        VStack {
                            Button(action: {}) {
                                VStack(spacing: 5) {
                                    Image(systemName: "heart")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 7)
                                .padding(.vertical, 7)
                            }
                            .buttonStyle(.glass)
                            .buttonBorderShape(.circle)
                            
                            Text("56")
                                .font(.headline)
                                .foregroundColor(.white)
                                .opacity(0.8)
                        }
                        
                        VStack {
                            Button(action: {
                                showCommentsSheet = true
                            }) {
                                VStack(spacing: 5) {
                                    Image(systemName: "text.bubble")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 7)
                                .padding(.vertical, 7)
                            }
                            .buttonStyle(.glass)
                            .buttonBorderShape(.circle)
                            
                            Text("144")
                                .font(.headline)
                                .foregroundColor(.white)
                                .opacity(0.8)
                        }
                    }
                    .offset(y: -20)
                }
                
                // Titre + artiste + année
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(post.track.title)
                                .font(.headline)
                                .textCase(.uppercase)
                                .foregroundColor(.white)
                            Text("• \(post.track.artist.name)")
                                .font(.subheadline)
                                .opacity(0.8)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Text("2023")
                            .font(.caption)
                            .opacity(0.7)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 25)
                .padding(.vertical, 15)
                
                Spacer() // ✅ Pousse le contenu du bas vers le haut
            }
        }
        .sheet(isPresented: $showCommentsSheet) {
            CommentsSheetView(post: post)
        }
    }
    
    func preloadImages() async {
        if coverUIImage != nil && avatarUIImage != nil { return }
        
        async let coverData = fetchImageData(from: post.track.coverUrl)
        async let avatarData = fetchImageData(from: post.photoUrl)
        
        if let data = await coverData, let uiImage = UIImage(data: data) {
            coverUIImage = uiImage
        }
        if let data = await avatarData, let uiImage = UIImage(data: data) {
            avatarUIImage = uiImage
        }
    }
    
    func fetchImageData(from urlString: String) async -> Data? {
        guard let url = URL(string: urlString) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        } catch {
            print("Erreur chargement image:", error)
            return nil
        }
    }
}
