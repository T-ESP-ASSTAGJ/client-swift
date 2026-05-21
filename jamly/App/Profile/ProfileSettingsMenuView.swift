// ProfileSettingsMenuView.swift

import SwiftUI

struct ProfileSettingsMenuView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var userStore: UserStore
    @EnvironmentObject private var musicManager: MusicManager

    @State private var showAccountParameters = false
    @State private var showMusicServices = false
    @State private var showAccountVisibility = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                SettingsRow(
                    icon: "person.circle.fill",
                    title: "Account Parameters",
                    subtitle: "Edit your profile info",
                    color: .blue
                ) {
                    showAccountParameters = true
                }

                SettingsRow(
                    icon: "music.note",
                    title: "Music Services",
                    subtitle: "Connect your streaming apps",
                    color: .purple
                ) {
                    showMusicServices = true
                }

                SettingsRow(
                    icon: "eye.fill",
                    title: "Privacy & Notifications",
                    subtitle: "Privacy & alerts settings",
                    color: .green
                ) {
                    showAccountVisibility = true
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)

            Spacer()

            Button {
                authManager.logout()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Disconnect")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.red.opacity(0.25), lineWidth: 1)
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
        }
        .background(Color.black)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showAccountParameters) {
            AccountSettingsView()
                .environmentObject(userStore)
        }
        .sheet(isPresented: $showMusicServices) {
            MusicSettingsView()
                .environmentObject(musicManager)
        }
        .sheet(isPresented: $showAccountVisibility) {
            AccountVisibilityView()
                .environmentObject(userStore)
        }
    }
}

// MARK: - Settings Row

private struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.gray.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}
