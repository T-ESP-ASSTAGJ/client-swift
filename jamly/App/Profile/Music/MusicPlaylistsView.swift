import SwiftUI
import MusicKit
import Combine

struct MusicPlaylistsView: View {
    @EnvironmentObject var musicManager: MusicManager
    
    // ✅ État pour gérer la navigation
    @State private var selectedPlaylist: Playlist?
    
    var body: some View {
#if targetEnvironment(simulator)
        VStack(spacing: 12) {
            Text("Apple Music non disponible sur le simulateur.")
                .font(.headline)
            Text("Teste cette fonctionnalité sur un iPhone réel ✨")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .navigationTitle("Mes Playlists")
        .navigationBarTitleDisplayMode(.inline)
#else
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                switch musicManager.authorizationStatus {
                case .notDetermined:
                    authorizationView
                    
                case .authorized:
                    if musicManager.isLoading {
                        loadingView
                    } else if musicManager.playlists.isEmpty {
                        emptyView
                    } else {
                        playlistsView
                    }
                    
                case .denied, .restricted:
                    deniedView
                    
                @unknown default:
                    Text("Statut inconnu")
                        .foregroundColor(.white)
                }
            }
        }
        .navigationTitle("Playlists")
        .navigationBarTitleDisplayMode(.large)
        // ✅ Navigation avec item (se déclenche quand selectedPlaylist n'est pas nil)
        .navigationDestination(item: $selectedPlaylist) { playlist in
            PlaylistDetailView(playlist: playlist)
        }

#endif
    }
    
    // MARK: - Views
    
    private var authorizationView: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(.pink)
            
            Text("Accède à tes playlists Apple Music")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Autoriser l'accès pour voir tes playlists")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Autoriser Apple Music") {
                Task { await musicManager.requestAuthorization() }
            }
            .buttonStyle(.borderedProminent)
            .foregroundColor(.black)
        }
        .padding()
    }
    
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Chargement des playlists...")
                .foregroundColor(.secondary)
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("Aucune playlist trouvée")
                .foregroundColor(.secondary)
        }
    }
    
    private var playlistsView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(musicManager.playlists, id: \.id) { playlist in
                    Button {
                        selectedPlaylist = playlist
                    } label: {
                        PlaylistRowContent(playlist: playlist)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contextMenu {
                        PlaylistContextMenu(playlist: playlist)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            Task {
                                await PlaylistShareService.shared.sharePlaylist(playlist)
                            }
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .tint(.blue)
                    }
                }
            }
            .padding()
        }
        .refreshable {
            await musicManager.loadPlaylists()
        }
    }
    
    private var deniedView: some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                VStack {
                    Text("Access Refused")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Activate access to Apple Music in Settings")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

// MARK: - Playlist Row

struct PlaylistRowContent: View {
    let playlist: Playlist
    
    var body: some View {
        HStack(spacing: 12) {
            // Image
            if let artwork = playlist.artwork {
                ArtworkImage(artwork, width: 60, height: 60)
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundColor(.white)
                    )
            }
            
            // Infos
            VStack(alignment: .leading, spacing: 5) {
                Text(playlist.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                if let count = playlist.tracks?.count {
                    Label("\(count) track(s)", systemImage: "music.note.list")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Chargement...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Playlist Context Menu

struct PlaylistContextMenu: View {
    let playlist: Playlist

    @State private var showShareSheet = false
    @State private var showShareToConversation = false

    var body: some View {
        Group {
            Button {
                showShareSheet = true
            } label: {
                Label("Share Link", systemImage: "square.and.arrow.up")
            }

            Button {
                showShareToConversation = true
            } label: {
                Label("Send in Message", systemImage: "message.fill")
            }

            Divider()

            Button {
                Task { await PlaylistShareService.shared.sharePlaylist(playlist) }
            } label: {
                Label("Share via Apple Music", systemImage: "applelogo")
            }

            Button {
                UIPasteboard.general.string = PlaylistShareService.shared.appleMusicURL(for: playlist)
            } label: {
                Label("Copy Link", systemImage: "doc.on.doc")
            }
        }
        .sheet(isPresented: $showShareSheet) {
            PlaylistShareSheetView(playlist: playlist)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showShareToConversation) {
            ShareToConversationView(playlist: playlist)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    NavigationStack {
        MusicPlaylistsView()
    }
    .preferredColorScheme(.dark)
}
