// AccountVisibilityView.swift

import SwiftUI

enum ProfileVisibility: String, CaseIterable, Identifiable {
    case everyone = "Everyone"
    case friends = "Friends Only"
    case nobody = "Only Me"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .everyone: return "globe"
        case .friends: return "person.2"
        case .nobody: return "lock.shield"
        }
    }
}

struct AccountVisibilityView: View {
    @EnvironmentObject private var userStore: UserStore
    @Environment(\.dismiss) private var dismiss

    @State private var profileVisibility: ProfileVisibility = .everyone
    @State private var showListeningActivity = true
    @State private var showPlaylists = true
    @State private var allowTagging = true

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Profile Visibility")) {
                    ForEach(ProfileVisibility.allCases) { option in
                        Button {
                            profileVisibility = option
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: option.icon)
                                    .foregroundColor(.white)
                                    .frame(width: 24)

                                Text(option.rawValue)
                                    .foregroundColor(.white)

                                Spacer()

                                if profileVisibility == option {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.white)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.05))
                    }
                }

                Section(header: Text("Activity")) {
                    Toggle(isOn: $showListeningActivity) {
                        HStack(spacing: 12) {
                            Image(systemName: "waveform")
                                .foregroundColor(.white)
                                .frame(width: 24)
                            Text("Show Listening Activity")
                                .foregroundColor(.white)
                        }
                    }
                    .tint(.white)
                    .listRowBackground(Color.white.opacity(0.05))

                    Toggle(isOn: $showPlaylists) {
                        HStack(spacing: 12) {
                            Image(systemName: "music.note.list")
                                .foregroundColor(.white)
                                .frame(width: 24)
                            Text("Show Playlists")
                                .foregroundColor(.white)
                        }
                    }
                    .tint(.white)
                    .listRowBackground(Color.white.opacity(0.05))

                    Toggle(isOn: $allowTagging) {
                        HStack(spacing: 12) {
                            Image(systemName: "at")
                                .foregroundColor(.white)
                                .frame(width: 24)
                            Text("Allow Tagging")
                                .foregroundColor(.white)
                        }
                    }
                    .tint(.white)
                    .listRowBackground(Color.white.opacity(0.05))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .navigationTitle("Visibility")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}
