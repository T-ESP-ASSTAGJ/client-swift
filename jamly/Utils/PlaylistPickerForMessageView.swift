import SwiftUI
import MusicKit
import Combine

/// View to pick and share a playlist directly within a conversation
struct PlaylistPickerForMessageView: View {
    let conversationId: Int
    let onPlaylistShared: () -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var musicManager: MusicManager
    private let shareService = PlaylistShareService.shared

    @State private var selectedPlaylist: Playlist?
    @State private var isSharing = false
    @State private var shareError: String?
    @State private var searchText = ""

    var filteredPlaylists: [Playlist] {
        searchText.isEmpty
            ? musicManager.playlists
            : musicManager.playlists.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    if !musicManager.playlists.isEmpty {
                        MusicPickerSearchBar(text: $searchText, placeholder: "Search playlists").padding()
                    }

                    if musicManager.isLoading {
                        Spacer()
                        ProgressView().tint(.white)
                        Spacer()
                    } else if musicManager.authorizationStatus != .authorized {
                        unauthorizedView
                    } else if filteredPlaylists.isEmpty {
                        emptyView
                    } else {
                        playlistsList
                    }
                }
            }
            .navigationTitle("Share Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send") { Task { await shareSelectedPlaylist() } }
                        .disabled(selectedPlaylist == nil || isSharing)
                        .foregroundStyle(
                            selectedPlaylist == nil
                                ? AnyShapeStyle(Color.gray)
                                : AnyShapeStyle(
                                    LinearGradient(
                                        colors: [Color(red: 0.6, green: 0.4, blue: 0.9), Color(red: 0.8, green: 0.4, blue: 0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
            }
            .task {
                if musicManager.playlists.isEmpty && musicManager.authorizationStatus == .authorized {
                    await musicManager.loadPlaylists()
                }
            }
            .shareErrorAlert($shareError)
            .overlay {
                if isSharing { SharingOverlay(label: "Sharing playlist...") }
            }
        }
    }

    // MARK: - Subviews

    private var playlistsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(filteredPlaylists, id: \.id) { playlist in
                    PlaylistPickerRow(
                        playlist: playlist,
                        isSelected: selectedPlaylist?.id == playlist.id,
                        onTap: { selectedPlaylist = playlist }
                    )
                }
            }
            .padding()
        }
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.list").font(.system(size: 50)).foregroundColor(.gray)
            Text(searchText.isEmpty ? "No playlists found" : "No results").foregroundColor(.secondary)
            if searchText.isEmpty {
                Button("Load Playlists") { Task { await musicManager.requestAuthorization() } }
                    .buttonStyle(.borderedProminent).foregroundColor(.black)
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var unauthorizedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list").font(.system(size: 60)).foregroundColor(.purple)
            Text("Access to Apple Music").font(.headline).foregroundColor(.white)
            Text("Authorize access to share your playlists")
                .font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
            Button("Authorize Apple Music") { Task { await musicManager.requestAuthorization() } }
                .buttonStyle(.borderedProminent).foregroundColor(.black)
        }
        .padding().frame(maxHeight: .infinity)
    }

    // MARK: - Actions

    private func shareSelectedPlaylist() async {
        guard let playlist = selectedPlaylist else { return }
        isSharing = true
        defer { isSharing = false }

        do {
            try await shareService.sharePlaylistToConversation(
                playlist,
                conversationId: conversationId
            )
            dismiss()
            onPlaylistShared()
        } catch let error as APIError where error.isPossiblePartialSuccess {
            dismiss()
            onPlaylistShared()
        } catch {
            shareError = error.localizedDescription
        }
    }
}

// MARK: - Playlist Picker Row

struct PlaylistPickerRow: View {
    let playlist: Playlist
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                if let artwork = playlist.artwork {
                    ArtworkImage(artwork, width: 60, height: 60).cornerRadius(8)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .overlay(Image(systemName: "music.note.list").foregroundColor(.white.opacity(0.5)))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(playlist.name).font(.headline).foregroundColor(.white).lineLimit(2)
                    if let tracks = playlist.tracks {
                        HStack(spacing: 4) {
                            Image(systemName: "music.note").font(.caption2)
                            Text("\(tracks.count) track(s)").font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.purple).font(.title2)
                }
            }
            .padding()
            .pickerRowBackground(isSelected: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    Text("Preview placeholder")
}
