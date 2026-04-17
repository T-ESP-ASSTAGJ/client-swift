import SwiftUI
import MusicKit

struct TrackPickerForMessageView: View {
    let conversationId: Int
    let onTrackShared: () -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var musicManager: MusicManager

    @State private var searchText = ""
    @State private var searchResults: [Song] = []
    @State private var selectedSong: Song?
    @State private var isSearching = false
    @State private var isSharing = false
    @State private var shareError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    searchBar.padding()

                    if isSearching {
                        Spacer()
                        ProgressView().tint(.white)
                        Spacer()
                    } else if searchText.isEmpty {
                        emptySearchView
                    } else if searchResults.isEmpty {
                        noResultsView
                    } else {
                        resultsList
                    }
                }
            }
            .navigationTitle("Share Track")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.pink)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send") { Task { await shareSelectedTrack() } }
                        .disabled(selectedSong == nil || isSharing)
                        .foregroundColor(selectedSong == nil ? .gray : .pink)
                }
            }
            .alert("Error", isPresented: .constant(shareError != nil)) {
                Button("OK") { shareError = nil }
            } message: {
                if let error = shareError { Text(error) }
            }
            .overlay {
                if isSharing {
                    ZStack {
                        Color.black.opacity(0.5).ignoresSafeArea()
                        VStack(spacing: 12) {
                            ProgressView().tint(.white).scaleEffect(1.5)
                            Text("Sharing track...").foregroundColor(.white).font(.caption)
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: searchText) {
            Task { await search(term: searchText) }
        }
    }

    // MARK: - Subviews

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(.gray)
            TextField("Search for a track...", text: $searchText)
                .foregroundColor(.white)
                .autocorrectionDisabled()
        }
        .padding(12)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }

    private var emptySearchView: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note").font(.system(size: 50)).foregroundColor(.gray)
            Text("Search for a track to share").foregroundColor(.secondary)
        }
        .frame(maxHeight: .infinity)
    }

    private var noResultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass").font(.system(size: 50)).foregroundColor(.gray)
            Text("No results for \"\(searchText)\"").foregroundColor(.secondary)
        }
        .frame(maxHeight: .infinity)
    }

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(searchResults, id: \.id) { song in
                    TrackPickerRow(
                        song: song,
                        isSelected: selectedSong?.id == song.id,
                        onTap: { selectedSong = song }
                    )
                }
            }
            .padding()
        }
    }

    // MARK: - Actions

    private func search(term: String) async {
        guard !term.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        isSearching = true
        defer { isSearching = false }
        searchResults = await musicManager.searchCatalog(term: term, limit: 20)
    }

    private func shareSelectedTrack() async {
        guard let song = selectedSong, let url = song.url else {
            shareError = "Unable to get track URL"
            return
        }
        isSharing = true
        defer { isSharing = false }

        do {
            let _ = try await MessageAction.sendShareMessage(
                conversationId: conversationId,
                content: url.absoluteString
            )
            dismiss()
            onTrackShared()
        } catch let error as APIError where error.isPossiblePartialSuccess {
            dismiss()
            onTrackShared()
        } catch {
            shareError = error.localizedDescription
        }
    }
}

// MARK: - Track Picker Row

struct TrackPickerRow: View {
    let song: Song
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                if let artwork = song.artwork {
                    ArtworkImage(artwork, width: 50, height: 50).cornerRadius(6)
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay(Image(systemName: "music.note").foregroundColor(.white.opacity(0.5)))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(song.title).font(.headline).foregroundColor(.white).lineLimit(1)
                    Text(song.artistName).font(.caption).foregroundColor(.secondary).lineLimit(1)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.pink).font(.title2)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.15) : Color.gray.opacity(0.1))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Color.pink : Color.clear, lineWidth: 2))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    Text("Preview placeholder")
}
