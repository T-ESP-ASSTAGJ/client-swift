import SwiftUI
import UIKit

/// Vue d'image asynchrone avec cache mémoire et downsampling.
///
/// Drop-in remplaçant pour `AsyncImage` quand on a besoin de performance et de
/// stabilité sur des listes (LazyVStack, ScrollView). Contrairement à `AsyncImage`,
/// l'image décodée reste en RAM tant que `ImageCache` ne l'évict pas, donc pas
/// de re-download au scroll.
struct CachedAsyncImage<Placeholder: View>: View {
    let url: URL?
    let targetSize: CGSize
    @ViewBuilder var placeholder: () -> Placeholder

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            guard let url else {
                image = nil
                return
            }
            let loaded = await ImageCache.shared.image(for: url, targetSize: targetSize)
            if !Task.isCancelled {
                image = loaded
            }
        }
    }
}
