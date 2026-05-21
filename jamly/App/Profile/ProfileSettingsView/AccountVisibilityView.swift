// AccountVisibilityView.swift

import SwiftUI

struct AccountVisibilityView: View {
    @EnvironmentObject private var userStore: UserStore
    @Environment(\.dismiss) private var dismiss

    @State private var params: UserParameter?
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var showSavedToast = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let binding = paramsBinding {
                    List {
                        Section(header: Text("Profile")) {
                            visibilityRow(
                                icon: "person.2",
                                title: "Followers",
                                selection: binding.followersVisibility
                            )
                            visibilityRow(
                                icon: "person.2.fill",
                                title: "Following",
                                selection: binding.followingVisibility
                            )
                            visibilityRow(
                                icon: "heart",
                                title: "Liked Posts",
                                selection: binding.likesVisibility
                            )
                        }

                        Section(header: Text("Activity")) {
                            visibilityRow(
                                icon: "waveform",
                                title: "Listening Activity",
                                selection: binding.statsVisibility
                            )
                            visibilityRow(
                                icon: "music.note.list",
                                title: "Playlists",
                                selection: binding.playlistVisibility
                            )
                        }

                        Section(header: Text("Notifications")) {
                            visibilityRow(
                                icon: "person.badge.plus",
                                title: "New Follower",
                                selection: binding.notifNewFollower
                            )
                            visibilityRow(
                                icon: "heart",
                                title: "New Like",
                                selection: binding.notifNewLike
                            )
                            visibilityRow(
                                icon: "bubble.left",
                                title: "New Comment",
                                selection: binding.notifNewComment
                            )
                            visibilityRow(
                                icon: "message",
                                title: "New Message",
                                selection: binding.notifNewMessage
                            )
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color.black)
                }
            }
            .background(Color.black)
            .navigationTitle("Privacy & Notifications")
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

                ToolbarItem(placement: .navigationBarTrailing) {
                    if isSaving {
                        ProgressView()
                            .tint(.white)
                    }
                }
            }
            .overlay(alignment: .top) {
                if showSavedToast {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                        Text("Saved")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.green.opacity(0.85)))
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .task { await loadParameters() }
    }

    // MARK: - Helpers

    private var paramsBinding: Binding<UserParameter>? {
        guard params != nil else { return nil }
        return Binding(
            get: { params! },
            set: { newValue in
                params = newValue
                Task { await save(newValue) }
            }
        )
    }

    private func visibilityRow(icon: String, title: String, selection: Binding<VisibilityOption>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .frame(width: 24)
            Text(title)
                .foregroundColor(.white)
            Spacer()
            Menu {
                ForEach(VisibilityOption.allCases, id: \.self) { option in
                    Button {
                        selection.wrappedValue = option
                    } label: {
                        Label(option.label, systemImage: option.icon)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: selection.wrappedValue.icon)
                        .font(.caption)
                    Text(selection.wrappedValue.label)
                        .font(.subheadline)
                }
                .foregroundColor(selection.wrappedValue.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(selection.wrappedValue.color.opacity(0.15))
                .cornerRadius(8)
            }
        }
        .listRowBackground(Color.white.opacity(0.02))
    }

    private func loadParameters() async {
        if let cached = userStore.userParameters {
            params = cached
            isLoading = false
            return
        }
        await userStore.fetchUserParameters()
        params = userStore.userParameters
        isLoading = false
    }

    private func save(_ updated: UserParameter) async {
        guard !isSaving else { return }
        isSaving = true
        let success = await userStore.updateUserParameters(updated)
        isSaving = false
        if success {
            withAnimation(.easeOut(duration: 0.3)) { showSavedToast = true }
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                withAnimation(.easeOut(duration: 0.3)) { showSavedToast = false }
            }
        }
    }
}
