// MusicSettingsView.swift
import SwiftUI
import MusicKit

struct MusicService: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    var isConnected: Bool
}

struct MusicSettingsView: View {
    @EnvironmentObject private var musicManager: MusicManager
    @Environment(\.dismiss) private var dismiss

    @State private var services: [MusicService] = [
        MusicService(name: "Spotify", icon: "waveform", color: .green, isConnected: false),
        MusicService(name: "Apple Music", icon: "music.note", color: .pink, isConnected: false),
        MusicService(name: "SoundCloud", icon: "cloud", color: .orange, isConnected: false),
        MusicService(name: "Deezer", icon: "headphones", color: .purple, isConnected: false)
    ]
    
    @State private var showingAuthorizationAlert = false
    @State private var isRequestingAuthorization = false
    @State private var showingSuccessMessage = false
    @State private var showingDisconnectAlert = false

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Available Services")) {
                    ForEach($services) { $service in
                        HStack(spacing: 14) {
                            Image(systemName: service.icon)
                                .font(.system(size: 22))
                                .foregroundColor(service.color)
                                .frame(width: 32)
                            Text(service.name)
                                .foregroundColor(.white)
                            Spacer()
                            Button {
                                handleServiceConnection(service: $service)
                            } label: {
                                if isRequestingAuthorization && service.name == "Apple Music" {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .frame(width: 80)
                                } else {
                                    Text(service.isConnected ? "Disconnect" : "Connect")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(service.isConnected ? .red : .black)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(service.isConnected ? Color.clear : Color.white)
                                        )
                                        .overlay(
                                            Capsule()
                                                .stroke(
                                                    service.isConnected ? Color.red.opacity(0.5) : Color.clear,
                                                    lineWidth: 1
                                                )
                                        )
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(isRequestingAuthorization)
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(Color.white.opacity(0.05))
                    }
                }
                Section(header: Text("Info")) {
                    Text("Connecting a music service lets Jamly sync your listening activity and playlists.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .listRowBackground(Color.white.opacity(0.05))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .navigationTitle("Music Services")
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
            .alert("Apple Music Access Required", isPresented: $showingAuthorizationAlert) {
                Button("Open Settings", role: .none) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Please enable Apple Music access in Settings to connect your account.")
            }
            .alert("Disconnect Apple Music?", isPresented: $showingDisconnectAlert) {
                Button("Disconnect", role: .destructive) {
                    musicManager.disconnect()
                    // Update UI
                    if let index = services.firstIndex(where: { $0.name == "Apple Music" }) {
                        services[index].isConnected = false
                    }
                }
                Button("Revoke Permission in Settings", role: .none) {
                    musicManager.disconnect()
                    // Update UI
                    if let index = services.firstIndex(where: { $0.name == "Apple Music" }) {
                        services[index].isConnected = false
                    }
                    // Open Settings
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will clear your playlists from the app. To fully revoke permission, you can go to Settings.")
            }
            .overlay(alignment: .top) {
                if showingSuccessMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                        Text("Apple Music Connected!")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green, lineWidth: 1)
                            )
                    )
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .task {
                // Update Apple Music connection status on appear
                await updateAppleMusicStatus()
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func handleServiceConnection(service: Binding<MusicService>) {
        if service.wrappedValue.name == "Apple Music" {
            Task {
                await handleAppleMusicConnection(service: service)
            }
        } else {
            // For other services (Spotify, SoundCloud, Deezer)
            // Implement OAuth or other connection logic here
            service.wrappedValue.isConnected.toggle()
        }
    }
    
    private func handleAppleMusicConnection(service: Binding<MusicService>) async {
        if service.wrappedValue.isConnected {
            // Show disconnect confirmation alert
            showingDisconnectAlert = true
        } else {
            // Connect: request authorization
            isRequestingAuthorization = true
            
            // Always check status fresh from the system
            let status = await musicManager.checkAuthorizationStatus()
            
            switch status {
            case .notDetermined:
                // Request authorization (will show system prompt)
                await musicManager.requestAuthorization()
                let newStatus = musicManager.authorizationStatus
                
                if newStatus == .authorized {
                    service.wrappedValue.isConnected = true
                    print("🎵 Apple Music connected and authorized")
                    
                    // Show success message
                    await showSuccessBanner()
                }
                
            case .authorized:
                // Already authorized, just connect and load
                musicManager.isConnected = true
                service.wrappedValue.isConnected = true
                
                // Load playlists if empty
                if musicManager.playlists.isEmpty {
                    Task.detached(priority: .background) {
                        await musicManager.loadPlaylists()
                    }
                }
                print("🎵 Apple Music already authorized")
                
                // Show success message
                await showSuccessBanner()
                
            case .denied, .restricted:
                // User has denied or is restricted
                showingAuthorizationAlert = true
                print("⚠️ Apple Music access denied or restricted")
                
            @unknown default:
                print("⚠️ Unknown authorization status")
            }
            
            isRequestingAuthorization = false
        }
    }
    
    private func updateAppleMusicStatus() async {
        let status = await musicManager.checkAuthorizationStatus()
        
        print("🔍 MusicSettings - Authorization Status: \(status)")
        print("🔍 MusicSettings - isConnected: \(musicManager.isConnected)")
        print("🔍 MusicSettings - Playlists count: \(musicManager.playlists.count)")
        
        // Update the Apple Music service connection status
        // Only show as connected if both authorized AND user has connected via settings
        if let index = services.firstIndex(where: { $0.name == "Apple Music" }) {
            services[index].isConnected = (status == .authorized && musicManager.isConnected)
            print("🔍 MusicSettings - Button shows connected: \(services[index].isConnected)")
        }
    }
    
    @MainActor
    private func showSuccessBanner() async {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showingSuccessMessage = true
        }
        
        try? await Task.sleep(nanoseconds: 2_500_000_000) // 2.5 seconds
        
        withAnimation(.easeOut(duration: 0.3)) {
            showingSuccessMessage = false
        }
    }
}
