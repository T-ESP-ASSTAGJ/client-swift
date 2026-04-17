import SwiftUI
import MusicKit

struct PlaylistDetailView: View {
    let playlist: Playlist
    
    private let player = ApplicationMusicPlayer.shared
    
    @EnvironmentObject var musicManager: MusicManager
    private let shareService = PlaylistShareService.shared
    
    @State private var isPlaying = false
    @State private var currentTrack: Track?
    @State private var showShareToConversation = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background gradient
            LinearGradient(
                colors: [.purple.opacity(0.3), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    largeArtworkView
                    playlistInfoView
                    actionsView
                    
                    if let tracks = playlist.tracks, !tracks.isEmpty {
                        tracksListView(tracks: Array(tracks))
                    } else {
                        emptyTracksView
                    }
                }
                // Padding en bas pour pas que le contenu soit caché par le mini player
                .padding(.bottom, currentTrack != nil ? 120 : 60)
            }
            
            // Mini Player
            if let track = currentTrack {
                MiniPlayerView(
                    track: track,
                    isPlaying: $isPlaying,
                    onPlayPause: { Task { await togglePlayPause() } }
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Large Artwork
    
    private var largeArtworkView: some View {
        VStack(spacing: 16) {
            if let artwork = playlist.artwork {
                ArtworkImage(artwork, width: 200, height: 200)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 200, height: 200)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 80))
                            .foregroundColor(.white.opacity(0.5))
                    )
            }
        }
        .padding(.bottom, 5)
        .padding(.top, 20)
    }
    
    // MARK: - Playlist Info
    
    private var playlistInfoView: some View {
        VStack(spacing: 12) {
            Text(playlist.name)
                .font(.title.bold())
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 20) {
                if let curatorName = playlist.curatorName {
                    Label(curatorName, systemImage: "person.circle.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let tracks = playlist.tracks {
                    Label("\(tracks.count) track(s)", systemImage: "music.note.list")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    // MARK: - Actions
    
    private var actionsView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: {
                    Task { await playAll() }
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Play")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.pink, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                
                Button(action: {
                    Task { await shufflePlay() }
                }) {
                    Image(systemName: "shuffle")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                }
            }
            
            // Share Options
            HStack(spacing: 12) {
                Button(action: {
                    showShareToConversation = true
                }) {
                    Image(systemName: "paperplane.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(
                            LinearGradient(
                                colors: [.pink, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                }
                
                // System share sheet for other apps
                Button(action: {
                    Task { await shareViaSystem() }
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(10)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .sheet(isPresented: $showShareToConversation) {
            ShareToConversationView(playlist: playlist)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Tracks List
    
    private func tracksListView(tracks: [Track]) -> some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                TrackRowView(track: track, index: index + 1)
                    .onTapGesture {
                        Task { await playTrack(track, from: tracks) }
                    }
                
                if index < tracks.count - 1 {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.leading, 70)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var emptyTracksView: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.slash")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("Aucun morceau dans cette playlist")
                .foregroundColor(.secondary)
        }
        .padding(.top, 40)
    }
    
    // MARK: - Actions Functions
    
    private func playTrack(_ track: Track, from tracks: [Track]) async {
        do {
            player.queue = ApplicationMusicPlayer.Queue(for: [track] + tracks.filter { $0.id != track.id })
            try await player.play()
            currentTrack = track
            isPlaying = true
        } catch {
            print("Erreur lecture track: \(error)")
        }
    }
    
    private func playAll() async {
        guard let tracks = playlist.tracks, let first = tracks.first else { return }
        await playTrack(first, from: Array(tracks))
    }
    
    private func togglePlayPause() async {
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            do {
                try await player.play()
                isPlaying = true
            } catch {
                print("Erreur lecture: \(error)")
            }
        }
    }
    
    private func shufflePlay() async {
        guard let tracks = playlist.tracks, !tracks.isEmpty else { return }
        do {
            let shuffledTracks = Array(tracks).shuffled()
            player.queue = ApplicationMusicPlayer.Queue(for: shuffledTracks)
            try await player.play()
            currentTrack = shuffledTracks.first
            isPlaying = true
        } catch {
            print("Erreur shuffle: \(error)")
        }
    }
    
    private func shareViaSystem() async {
        await shareService.sharePlaylist(playlist)
    }
}

// MARK: - Mini Player View

struct MiniPlayerView: View {
    let track: Track
    @Binding var isPlaying: Bool
    let onPlayPause: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Cover
            if let artwork = track.artwork {
                ArtworkImage(artwork, width: 45, height: 45)
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 45, height: 45)
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundColor(.white.opacity(0.5))
                    )
            }
            
            // Titre + Artiste
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(track.artistName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Play/Pause
            Button(action: onPlayPause) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            .padding(.trailing, 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.black.opacity(0.4))
                .glassEffect(.clear.interactive(true), in: .rect(cornerRadius: 16))
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 15)
    }
}

// MARK: - Track Row View

struct TrackRowView: View {
    let track: Track
    let index: Int
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(index)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 25)
            
            if let artwork = track.artwork {
                ArtworkImage(artwork, width: 45, height: 45)
                    .cornerRadius(6)
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 45, height: 45)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.body)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(track.artistName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if let duration = track.duration {
                Text(formatDuration(duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button(action: {}) {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
