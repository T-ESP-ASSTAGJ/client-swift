import Foundation
import MusicKit
import SwiftUI

@MainActor
final class PlaylistShareService {

    static let shared = PlaylistShareService()

    private init() {
        // Intentionally empty — prevents external instantiation (singleton pattern)
    }

    // MARK: - Share via iOS share sheet

    func sharePlaylist(_ playlist: Playlist) async {
        let shareURL = appleMusicURL(for: playlist)
        let shareText = "🎵 Check out this playlist: \(playlist.name)"
        await presentShareSheet(items: [shareText, shareURL])
    }

    // MARK: - Share to conversation

    /// Only the playlist name and Apple Music URL are stored in the message.
    /// Artwork and details are fetched at display time via MusicKit.
    func sharePlaylistToConversation(
        _ playlist: Playlist,
        conversationId: Int
    ) async throws {
        let shareURL = appleMusicURL(for: playlist)

        // Only send the URL — name and artwork are fetched from MusicKit at display time
        let _ = try await MessageAction.sendShareMessage(
            conversationId: conversationId,
            content: shareURL
        )

    }

    // MARK: - Helpers

    /// Returns the best Apple Music URL for a playlist.
    /// Catalog playlists have a direct URL; library playlists fall back to search.
    func appleMusicURL(for playlist: Playlist) -> String {
        if let url = playlist.url?.absoluteString { return url }
        let id = playlist.id.rawValue
        if id.hasPrefix("p.") {
            let encoded = playlist.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return "\(Config.appleMusicBaseURL)/search?term=\(encoded)"
        }
        return "\(Config.appleMusicBaseURL)\(Config.appleMusicPlaylistPath)\(id)"
    }

    private func presentShareSheet(items: [Any]) async {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController else { return }

        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = window
            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        rootVC.present(activityVC, animated: true)
    }
}

