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
    @State private var allTracks: [Track] = []
    @State private var filteredTracks: [Track] = []
    @State private var isLoadingSongs = false
    
    @Binding var selectedSong: Track?
    @Binding var frontImage: UIImage?
    @Binding var backImage: UIImage?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color(hex: "0C0C0C"), Color(hex: "1A1A1A")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    searchBar
                    
                    // Content
                    if isLoadingSongs {
                        loadingView
                    } else if searchText.isEmpty {
                        initialContentView
                    } else {
                        searchResultsView
                    }
                }
            }
            .navigationTitle("Choose a song")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: closeButton)
            .onAppear {
                loadUserTracks()
            }
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
                    filterTracks(query: newValue)
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
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
                Text("Loading of your library...")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.gray)
            }
            Spacer()
        }
    }
    
    private var initialContentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if allTracks.isEmpty {
                    emptyStateView
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your library (\(allTracks.count) songs)")
                            .font(.custom("Poppins-Bold", size: 20))
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        ForEach(allTracks.prefix(100), id: \.id) { track in
                            TrackRow(
                                track: track,
                                hasFrontImage: frontImage != nil,
                                hasBackImage: backImage != nil
                            ) { placement in
                                handleTrackSelection(track: track, placement: placement)
                            }
                        }
                        
                        if allTracks.count > 100 {
                            Text("+ \(allTracks.count - 100) other songs")
                                .font(.custom("Poppins-Regular", size: 13))
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("No song found")
                .font(.custom("Poppins-SemiBold", size: 18))
                .foregroundColor(.white)
            
            Text("Number of playlists: \(musicManager.playlists.count)")
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.yellow)
            
            Text("Add music into your library to see it here.")
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
    }
    
    private var searchResultsView: some View {
        Group {
            if filteredTracks.isEmpty {
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
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredTracks, id: \.id) { track in
                            TrackRow(
                                track: track,
                                hasFrontImage: frontImage != nil,
                                hasBackImage: backImage != nil
                            ) { placement in
                                handleTrackSelection(track: track, placement: placement)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func handleTrackSelection(track: Track, placement: CoverPlacement?) {
        selectedSong = track
        
        // Si l'utilisateur veut utiliser la cover
        if let placement = placement, let artwork = track.artwork {
            Task {
                // Charger l'image de la cover
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
                    await MainActor.run {
                        dismiss()
                    }
                }
            }
        } else {
            dismiss()
        }
    }
    
    private func loadUserTracks() {
        isLoadingSongs = true
        
        print("🔍 Nombre de playlists: \(musicManager.playlists.count)")
        
        var tracks: [Track] = []
        
        for playlist in musicManager.playlists {
            if let playlistTracks = playlist.tracks {
                print("📋 Playlist '\(playlist.name)': \(playlistTracks.count) tracks")
                tracks.append(contentsOf: Array(playlistTracks))
            } else {
                print("⚠️ Playlist '\(playlist.name)': pas de tracks")
            }
        }
        
        print("✅ Total tracks trouvés: \(tracks.count)")
        
        let uniqueTracks = Array(Set(tracks.map { $0.id })).compactMap { id in
            tracks.first(where: { $0.id == id })
        }
        
        print("✅ Tracks uniques: \(uniqueTracks.count)")
        
        allTracks = uniqueTracks.sorted { $0.title < $1.title }
        isLoadingSongs = false
    }
    
    private func filterTracks(query: String) {
        guard !query.isEmpty else {
            filteredTracks = []
            return
        }
        
        let lowercasedQuery = query.lowercased()
        filteredTracks = allTracks.filter { track in
            track.title.lowercased().contains(lowercasedQuery) ||
            track.artistName.lowercased().contains(lowercasedQuery)
        }
    }
}

// MARK: - Track Row
struct TrackRow: View {
    let track: Track
    let hasFrontImage: Bool
    let hasBackImage: Bool
    let onSelect: (CoverPlacement?) -> Void
    
    @State private var showCoverAlert = false
    
    var body: some View {
        Button(action: {
            // Si le track a une artwork, proposer de l'utiliser
            if track.artwork != nil {
                showCoverAlert = true
            } else {
                onSelect(nil)
            }
        }) {
            HStack(spacing: 12) {
                // Album Artwork
                if let artwork = track.artwork {
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
                
                // Song Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.title)
                        .font(.custom("Poppins-SemiBold", size: 15))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(track.artistName)
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
                onSelect(.front)
            }
            
            Button(hasBackImage ? "Replace the back image" : "Back image") {
                onSelect(.back)
            }
            
            Button("No") {
                onSelect(nil)
            }
            
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You can use the cover of \"\(track.title)\" for your post")
        }
    }
}

// MARK: - Preview
#Preview {
    MusicPickerView(
        selectedSong: .constant(nil),
        frontImage: .constant(nil),
        backImage: .constant(nil)
    )
    .environmentObject(MusicManager())
}
