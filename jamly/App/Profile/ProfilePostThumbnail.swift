//
//  ProfilePostThumbnail.swift
//  Jamly
//
//  Created by REVERSS on 06/01/2026.
//

import SwiftUI

struct ProfilePostThumbnail: View {
    let imageURL: String
    
    @State private var thumbnailImage: UIImage?
    
    var body: some View {
        ZStack {
            if let img = thumbnailImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.gray.opacity(0.2)
                    .overlay {
                        ProgressView()
                            .tint(.white.opacity(0.5))
                    }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipped()
        .task {
            await loadThumbnail()
        }
    }
    
    private func loadThumbnail() async {
        let fullURL = buildFullImageURL(imageURL)
        
        guard let url = URL(string: fullURL) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data) {
                await MainActor.run {
                    self.thumbnailImage = uiImage
                }
            }
        } catch {
            print("❌ Error loading thumbnail: \(error)")
        }
    }
    
    private func buildFullImageURL(_ urlString: String) -> String {
        // Si c'est déjà une URL complète, retourner telle quelle
        if urlString.starts(with: "http://") || urlString.starts(with: "https://") {
            return urlString
        }
        
        // Sinon, ajouter le base URL
        let baseURL = "http://10.68.245.78:80"
        return baseURL + urlString
    }
}
