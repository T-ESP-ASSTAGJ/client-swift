//
//  ProfileStatsView.swift
//  jamly
//

import SwiftUI
import MusicKit

struct ProfileStatsView: View {
    @ObservedObject var viewModel: ProfileStatsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                    .padding(.bottom, 40)
            } else if !viewModel.isAppleMusicConnected {
                notConnectedView
            } else {
                content
            }
        }
        .task { await viewModel.loadStats() }
    }

    // MARK: - Empty State (Apple Music non connecté)

    private var notConnectedView: some View {
        EmptyStateView(
            icon: "music.note.list",
            title: "Apple Music not connected",
            subtitle: "Connect your Apple Music account to unlock listening stats."
        )
        .padding(.vertical, 40)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 16) {
            listeningTimeCard

            if !viewModel.topTracks.isEmpty {
                topTracksSection
            }

            if !viewModel.topArtists.isEmpty {
                topArtistsSection
            }

            if !viewModel.recentHistory.isEmpty {
                recentHistorySection
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    // MARK: - Listening Time Card

    private var listeningTimeCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Temps d'écoute estimé")
                .font(.caption)
                .foregroundColor(.gray)

            Text(viewModel.formattedListeningTime)
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                }
        )
    }

    // MARK: - Top Tracks

    private var topTracksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top morceaux")
                .font(.headline)
                .foregroundColor(.white)

            VStack(spacing: 0) {
                ForEach(Array(viewModel.topTracks.enumerated()), id: \.offset) { index, song in
                    trackRow(index: index, song: song)

                    if index < viewModel.topTracks.count - 1 {
                        Divider().overlay(Color.white.opacity(0.07))
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.08), lineWidth: 1)
                    }
            )
        }
    }

    private func trackRow(index: Int, song: Song) -> some View {
        HStack(spacing: 12) {
            Text("\(index + 1)")
                .font(.caption.weight(.bold))
                .foregroundColor(.gray)
                .frame(width: 18)

            if let artwork = song.artwork {
                ArtworkImage(artwork, width: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(song.artistName)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }

            Spacer()

            if let plays = song.playCount {
                Text("\(plays)×")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Top Artists

    private var topArtistsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top artistes")
                .font(.headline)
                .foregroundColor(.white)

            VStack(spacing: 0) {
                ForEach(Array(viewModel.topArtists.enumerated()), id: \.offset) { index, artist in
                    artistRow(index: index, artist: artist)

                    if index < viewModel.topArtists.count - 1 {
                        Divider().overlay(Color.white.opacity(0.07))
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.08), lineWidth: 1)
                    }
            )
        }
    }

    // MARK: - Recent History

    private var recentHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Historique récent")
                .font(.headline)
                .foregroundColor(.white)

            VStack(spacing: 0) {
                ForEach(Array(viewModel.recentHistory.enumerated()), id: \.offset) { index, song in
                    HStack(spacing: 12) {
                        if let artwork = song.artwork {
                            ArtworkImage(artwork, width: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        } else {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40, height: 40)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(song.title)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.white)
                                .lineLimit(1)

                            Text(song.artistName)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 8)

                    if index < viewModel.recentHistory.count - 1 {
                        Divider().overlay(Color.white.opacity(0.07))
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.08), lineWidth: 1)
                    }
            )
        }
    }

    private func artistRow(index: Int, artist: ArtistStat) -> some View {
        HStack(spacing: 12) {
            Text("\(index + 1)")
                .font(.caption.weight(.bold))
                .foregroundColor(.gray)
                .frame(width: 18)

            if let artwork = artist.artwork {
                ArtworkImage(artwork, width: 40)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
            }

            Text(artist.name)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer()

            Text("\(artist.playCount)×")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}
