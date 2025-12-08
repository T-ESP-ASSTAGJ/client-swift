//
//  JamPostCard.swift
//  jamly
//
//  Created by REVERSS on 05/12/2025.
//

import SwiftUI

struct PostCard: View {
    let post: JamPost

    @State private var coverUIImage: UIImage?
    @State private var avatarUIImage: UIImage?
    @State private var isSwapped = false

    var body: some View {
        VStack(alignment: .center) {
            HStack {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(post.authorAvatarName)
                            .resizable()
                            .scaledToFill()
                            .clipShape(Circle())
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName)
                        .font(.subheadline.weight(.semibold))
                    Text(post.location)
                        .font(.caption)
                        .opacity(0.7)
                }

                Spacer()

                Text(post.timeString)
                    .font(.caption)
                    .opacity(0.7)
            }.padding(15)
            ZStack(alignment: .bottom) {
                // Cover + avatar listener
                ZStack(alignment: .topTrailing) {
                    // IMAGE PRINCIPALE (comme BeReal, super fluide)
                    Group {
                        if let img = isSwapped ? avatarUIImage : coverUIImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Color.gray.opacity(0.2)  // placeholder
                        }
                    }
                    .frame(width: 370, height: 420)
                    .clipShape(RoundedRectangle(cornerRadius: 24))

                    // BOUTON EN HAUT À DROITE (miniature BeReal)
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSwapped.toggle()
                        }
                    } label: {
                        ZStack {
                            if let img = isSwapped
                                ? coverUIImage : avatarUIImage
                            {
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
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
                .task {
                    await preloadImages()
                }
                
                ZStack(alignment: .bottom) {
                    // Statistiques
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
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.circle)
                            
                            Text("\(post.likes)")
                                .font(.headline)
                                .foregroundColor(.white)
                                .opacity(0.8)
                        }
                        
                        VStack {
                            Button(action: {}) {
                                VStack(spacing: 5) {
                                    Image(systemName: "text.bubble")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                }
                                .padding(.horizontal, 7)
                                .padding(.vertical, 7)
                            }
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.circle)
                            
                            Text("\(post.likes)")
                                .font(.headline)
                                .foregroundColor(.white)
                                .opacity(0.8)
                        }
                    }
                }.offset(y: -20)
            }
            
            // Titre + sous-titre + année
            ZStack {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(post.title)
                                .font(.headline)
                                .textCase(.uppercase)
                                .foregroundColor(.white)
                            Text("• \(post.subtitle)")
                                .font(.subheadline)
                                .opacity(0.8)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Text(post.year)
                            .font(.caption)
                            .opacity(0.7)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 15)
        }
    }

    func preloadImages() async {
        // Si déjà chargées, ne refait rien
        if coverUIImage != nil && avatarUIImage != nil { return }

        async let coverData = fetchImageData(from: post.coverImageName)
        async let avatarData = fetchImageData(from: post.listenerAvatarName)

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

#Preview {
    PostCard(post: JamPost.mock[0])
        .preferredColorScheme(.dark)
}
