import UIKit
import ImageIO

/// Cache mémoire d'images avec downsampling et déduplication des requêtes en vol.
///
/// - Le coût mémoire est borné (`totalCostLimit`) : NSCache éjecte automatiquement
///   les entrées les moins récemment utilisées sous pression mémoire.
/// - Les images sont décodées à la taille d'affichage (downsampling via ImageIO),
///   ce qui divise la RAM consommée par ~25 sur des images 500×500 affichées en 32×32.
/// - Les requêtes simultanées sur la même URL sont coalescées en une seule.
@MainActor
final class ImageCache {

    // MARK: - Singleton
    static let shared = ImageCache()

    // MARK: - Storage
    private let cache: NSCache<NSString, UIImage>
    private var inFlightTasks: [String: Task<UIImage?, Never>] = [:]

    private init() {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 200
        cache.totalCostLimit = 20 * 1024 * 1024 // 20 MB
        self.cache = cache
    }

    // MARK: - Public API

    /// Récupère l'image décodée à la taille demandée (cache mémoire, sinon download).
    func image(for url: URL, targetSize: CGSize) async -> UIImage? {
        let key = Self.cacheKey(url: url, size: targetSize)
        let nsKey = key as NSString

        if let cached = cache.object(forKey: nsKey) {
            return cached
        }

        // Coalesce les requêtes simultanées sur la même URL/taille
        if let existing = inFlightTasks[key] {
            return await existing.value
        }

        let scale = UIScreen.main.scale

        let task = Task.detached(priority: .userInitiated) { () -> UIImage? in
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                return await Self.downsample(data: data, to: targetSize, scale: scale)
            } catch {
                return nil
            }
        }
        inFlightTasks[key] = task

        let image = await task.value
        inFlightTasks[key] = nil

        if let image {
            let pixelWidth = image.size.width * image.scale
            let pixelHeight = image.size.height * image.scale
            let cost = Int(pixelWidth * pixelHeight * 4) // RGBA
            cache.setObject(image, forKey: nsKey, cost: cost)
        }

        return image
    }

    // MARK: - Private

    private static func cacheKey(url: URL, size: CGSize) -> String {
        "\(url.absoluteString)|\(Int(size.width))x\(Int(size.height))"
    }

    /// Downsampling via ImageIO : décode directement à la taille cible sans charger
    /// l'image complète en mémoire.
    private static func downsample(data: Data, to size: CGSize, scale: CGFloat) -> UIImage? {
        let maxPixelSize = max(size.width, size.height) * scale

        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else {
            return nil
        }

        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ] as CFDictionary

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions) else {
            return nil
        }

        return UIImage(cgImage: cgImage, scale: scale, orientation: .up)
    }
}
