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
            List {
                Section {
                    Button {
                        showAccountParameters = true
                    } label: {
                        SettingsRow(icon: "person.circle", title: "Account Parameters")
                    }
                    .listRowBackground(Color.white.opacity(0.05))

                    Button {
                        showMusicServices = true
                    } label: {
                        SettingsRow(icon: "music.note", title: "Music Services")
                    }
                    .listRowBackground(Color.white.opacity(0.05))

                    Button {
                        showAccountVisibility = true
                    } label: {
                        SettingsRow(icon: "eye", title: "Account Visibility")
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                }
            }
            .scrollContentBackground(.hidden)

            Spacer()

            Button(action: {
                authManager.logout()
            }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Disconnect")
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(Color.black)
        .navigationTitle("Settings")
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

struct SettingsRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 28)

            Text(title)
                .foregroundColor(.white)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray)
        }
    }
}
