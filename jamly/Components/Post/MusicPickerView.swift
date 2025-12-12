//
//  MusicPickerView.swift
//  jamly
//
//  Created by REVERSS on 08/12/2025.
//

import SwiftUI
import MusicKit

// MARK: - Music Picker View
struct MusicPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var musicManager: MusicManager
    @Binding var selectedSong: Song?
    @State private var searchText = ""
    @State private var allTracks: [Track] = []
    @State private var filteredTracks: [Track] = []
    @State private var isLoadingSongs = false
    
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
            .navigationTitle("Choisir une musique")
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
            
            TextField("Rechercher une chanson...", text: $searchText)
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
        Button("Fermer") {
            dismiss()
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
                Text("Chargement de votre bibliothèque...")
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
                    // Afficher tous les tracks
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Votre bibliothèque (\(allTracks.count) chansons)")
                            .font(.custom("Poppins-Bold", size: 20))
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        ForEach(allTracks.prefix(100), id: \.id) { track in
                            TrackRow(track: track) {
                                // Essayer de convertir Track en Song
                                if let song = track as? Song {
                                    selectedSong = song
                                }
                                dismiss()
                            }
                        }
                        
                        if allTracks.count > 100 {
                            Text("+ \(allTracks.count - 100) autres chansons")
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
            
            Text("Aucune chanson trouvée")
                .font(.custom("Poppins-SemiBold", size: 18))
                .foregroundColor(.white)
            
            Text("Nombre de playlists: \(musicManager.playlists.count)")
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.yellow)
            
            Text("Ajoutez de la musique à votre bibliothèque Apple Music")
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
                        
                        Text("Aucun résultat")
                            .font(.custom("Poppins-Medium", size: 16))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredTracks, id: \.id) { track in
                            TrackRow(track: track) {
                                if let song = track as? Song {
                                    selectedSong = song
                                }
                                dismiss()
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func loadUserTracks() {
        isLoadingSongs = true
        
        print("🔍 Nombre de playlists: \(musicManager.playlists.count)")
        
        // Récupérer tous les tracks des playlists déjà chargées
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
        
        // Supprimer les doublons (même ID)
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
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
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
    }
}

// MARK: - Preview
#Preview {
    MusicPickerView(selectedSong: .constant(nil))
        .environmentObject(MusicManager())
}
