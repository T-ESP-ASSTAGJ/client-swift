import SwiftUI
import MusicKit

/// Sheet to share a playlist via the iOS share sheet (Apple Music only)
struct PlaylistShareSheetView: View {
    let playlist: Playlist

    @Environment(\.dismiss) private var dismiss
    private let shareService = PlaylistShareService.shared

    @State private var isCopied = false

    var appleMusicURL: String {
        shareService.appleMusicURL(for: playlist)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Playlist header
                    HStack(spacing: 16) {
                        if let artwork = playlist.artwork {
                            ArtworkImage(artwork, width: 70, height: 70).cornerRadius(8)
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 70, height: 70)
                                .overlay(Image(systemName: "music.note.list").foregroundColor(.white))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(playlist.name).font(.headline).foregroundColor(.white)
                            HStack(spacing: 6) {
                                Image(systemName: "applelogo").font(.caption).foregroundColor(.pink)
                                Text("Apple Music").font(.caption).foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Actions
                    VStack(spacing: 12) {
                        // Copy link
                        Button {
                            UIPasteboard.general.string = appleMusicURL
                            withAnimation { isCopied = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { isCopied = false }
                            }
                        } label: {
                            HStack {
                                Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                                    .foregroundColor(isCopied ? .green : .white)
                                Text(isCopied ? "Copied!" : "Copy Apple Music Link")
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())

                        // Share via iOS share sheet
                        Button {
                            Task {
                                await shareService.sharePlaylist(playlist)
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share via Apple Music")
                                Spacer()
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Share Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(.pink)
                }
            }
        }
    }
}

#Preview {
    Text("Preview placeholder")
}
