//
//  MusicPickerView.swift
//  jamly
//
//  Created by REVERSS on 08/12/2025.
//

import SwiftUI
import MusicKit

// MARK: - Cover Placement Enum
enum CoverPlacement {
    case front
    case back
}

// MARK: - Music Picker View
struct MusicPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var musicManager: MusicManager

    @State private var searchText = ""
    @State private var searchResults: [Song] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    @State private var isResolving = false

    @Binding var selectedSong: Song?
    @Binding var selectedCatalogID: String?
    @Binding var frontImage: UIImage?
    @Binding var backImage: UIImage?

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "0C0C0C"), Color(hex: "1A1A1A")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    searchBar

                    if isSearching {
                        loadingView
                    } else if searchText.isEmpty {
                        if musicManager.playlists.isEmpty {
                            emptySearchView
                        } else {
                            libraryView
                        }
                    } else if searchResults.isEmpty {
                        noResultsView
                    } else {
                        searchResultsView
                    }
                }

                if isResolving {
                    SharingOverlay(label: "Loading...")
                }
            }
            .navigationTitle("Choose a song")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: closeButton)
            .task { await loadLibraryIfNeeded() }
        }
    }

    // MARK: - Subviews

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField("Search a song...", text: $searchText)
                .font(.custom("Poppins-Regular", size: 15))
                .foregroundColor(.white)
                .autocorrectionDisabled()
                .onChange(of: searchText) { _, newValue in
                    debouncedSearch(query: newValue)
                }

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    searchResults = []
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
        .padding()
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Label("close", systemImage: "xmark")
        }
        .font(.custom("Poppins-Medium", size: 15))
        .foregroundColor(.white)
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            VStack(spacing: 16) {
                ProgressView()
                    .tint(.white)
                Text("Searching...")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.gray)
            }
            Spacer()
        }
    }

    private var emptySearchView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text("Search for a song")
                .font(.custom("Poppins-SemiBold", size: 18))
                .foregroundColor(.white)

            Text("Search by title or artist in the Apple Music catalog.")
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    private var noResultsView: some View {
        VStack {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 48))
                    .foregroundColor(.gray)

                Text("No result found")
                    .font(.custom("Poppins-Medium", size: 16))
                    .foregroundColor(.gray)
            }
            Spacer()
        }
    }

    private var libraryView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                Text("Your playlists")
                    .font(.custom("Poppins-SemiBold", size: 14))
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                    .padding(.bottom, 4)

                ForEach(musicManager.playlists, id: \.id) { playlist in
                    if let tracks = playlist.tracks, !tracks.isEmpty {
                        Text(playlist.name)
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .padding(.top, 16)
                            .padding(.bottom, 4)

                        ForEach(tracks, id: \.id) { track in
                            MusicPickerRow(
                                title: track.title,
                                artistName: track.artistName,
                                artwork: track.artwork,
                                hasFrontImage: frontImage != nil,
                                hasBackImage: backImage != nil
                            ) { placement in
                                Task { await handleLibraryTrackSelection(track, placement: placement) }
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }

    private var searchResultsView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(searchResults, id: \.id) { song in
                    MusicPickerRow(
                        title: song.title,
                        artistName: song.artistName,
                        artwork: song.artwork,
                        hasFrontImage: frontImage != nil,
                        hasBackImage: backImage != nil
                    ) { placement in
                        Task { await handleSongSelection(song: song, placement: placement) }
                    }
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - Helper Functions

    /// Charge les playlists de la bibliothèque si elles ne sont pas encore disponibles,
    /// afin d'avoir de la matière à proposer sans que l'utilisateur ait à chercher.
    private func loadLibraryIfNeeded() async {
        guard musicManager.playlists.isEmpty else { return }
        guard musicManager.authorizationStatus == .authorized else { return }
        await musicManager.loadPlaylists()
    }

    /// Résout un morceau de playlist vers un `Song` catalogue puis le sélectionne.
    private func handleLibraryTrackSelection(_ track: Track, placement: CoverPlacement?) async {
        isResolving = true
        defer { isResolving = false }

        guard let song = await musicManager.resolveCatalogSong(for: track) else { return }

        await handleSongSelection(song: song, placement: placement)
    }

    private func debouncedSearch(query: String) {
        searchTask?.cancel()

        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            isSearching = false
            return
        }

        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }

            isSearching = true
            let results = await musicManager.searchCatalog(term: query)

            guard !Task.isCancelled else { return }
            searchResults = results
            isSearching = false
        }
    }

    private func handleSongSelection(song: Song, placement: CoverPlacement?) async {
        selectedCatalogID = song.id.rawValue

        // Convert Song to a lightweight binding — MusicPickerView used Track before,
        // but catalog search returns Song. We pass nil for selectedSong (Track binding)
        // and set catalogID + dismiss. CreatePostViewModel uses catalogID + song metadata.
        selectedSong = song

        if let placement = placement, let artwork = song.artwork {
            if let url = artwork.url(width: 800, height: 800),
               let (data, _) = try? await URLSession.shared.data(from: url),
               let image = UIImage(data: data) {
                await MainActor.run {
                    switch placement {
                    case .front:
                        frontImage = image
                    case .back:
                        backImage = image
                    }
                    dismiss()
                }
            } else {
                await MainActor.run { dismiss() }
            }
        } else {
            dismiss()
        }
    }
}

// MARK: - Track Picker Row (shared)

/// Ligne unique factorisée pour les morceaux catalogue (Song) et bibliothèque (Track).
/// Affiche la pochette, le titre/artiste et propose un confirmationDialog pour utiliser
/// la cover comme front/back image du post.
struct MusicPickerRow: View {
    let title: String
    let artistName: String
    let artwork: Artwork?
    let hasFrontImage: Bool
    let hasBackImage: Bool
    let onSelect: (CoverPlacement?) async -> Void

    @State private var showCoverAlert = false

    var body: some View {
        Button(action: {
            if artwork != nil {
                showCoverAlert = true
            } else {
                Task { await onSelect(nil) }
            }
        }) {
            HStack(spacing: 12) {
                if let artwork {
                    ArtworkImage(artwork, width: 60, height: 60)
                        .cornerRadius(8)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "music.note")
                                .foregroundColor(.gray)
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.custom("Poppins-SemiBold", size: 15))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(artistName)
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .confirmationDialog(
            "Use the cover ?",
            isPresented: $showCoverAlert,
            titleVisibility: .visible
        ) {
            Button(hasFrontImage ? "Replace the front image" : "Front image") {
                Task { await onSelect(.front) }
            }

            Button(hasBackImage ? "Replace the back image" : "Back image") {
                Task { await onSelect(.back) }
            }

            Button("No") {
                Task { await onSelect(nil) }
            }

            Button("Cancel", role: .cancel) {
                // No-op : SwiftUI ferme automatiquement le confirmationDialog pour les boutons .cancel.
            }
        } message: {
            Text("You can use the cover of \"\(title)\" for your post")
        }
    }
}

// MARK: - Preview
#Preview {
    MusicPickerView(
        selectedSong: .constant(nil),
        selectedCatalogID: .constant(nil),
        frontImage: .constant(nil),
        backImage: .constant(nil)
    )
    .environmentObject(MusicManager())
}
