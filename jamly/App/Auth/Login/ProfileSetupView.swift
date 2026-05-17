import SwiftUI
import PhotosUI

struct ProfileSetupView: View {
    @EnvironmentObject private var userStore: UserStore

    @State private var username: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var animateContent = false
    @FocusState private var usernameFocused: Bool

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.15, blue: 0.2),
                    Color(red: 0.08, green: 0.08, blue: 0.12),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Ambient circles
            GeometryReader { geometry in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.cyan.opacity(0.25), Color.blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 280, height: 280)
                    .blur(radius: 95)
                    .offset(x: -80, y: -30)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.easeInOut(duration: 1.5), value: animateContent)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.3), Color.pink.opacity(0.2)],
                            startPoint: .bottomLeading,
                            endPoint: .topTrailing
                        )
                    )
                    .frame(width: 220, height: 220)
                    .blur(radius: 85)
                    .offset(x: geometry.size.width - 120, y: geometry.size.height - 150)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.easeInOut(duration: 1.5).delay(0.2), value: animateContent)
            }

            // Main content
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Bienvenue")
                            .font(.custom("Poppins-Bold", size: 42))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, Color(white: 0.9)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .cyan.opacity(0.3), radius: 20, x: 0, y: 10)

                        Text("Quelques infos pour commencer")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                    }
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : -20)
                    .animation(.easeOut(duration: 0.8), value: animateContent)

                    // Card
                    VStack(spacing: 24) {
                        // Profile picture picker
                        profilePictureSection

                        // Username field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Username")
                                .font(.custom("Poppins-Regular", size: 15))
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(0.5)

                            TextField("", text: $username, prompt: Text("johndoe")
                                .foregroundColor(.white.opacity(0.3)))
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .textContentType(.username)
                                .font(.custom("Poppins-Regular", size: 16))
                                .foregroundColor(.white)
                                .tint(.white)
                                .focused($usernameFocused)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.white.opacity(0.05))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(.white.opacity(0.1), lineWidth: 1)
                                        )
                                )
                        }

                        // Error message
                        if let error = errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.caption)
                                Text(error)
                                    .font(.custom("Poppins-Regular", size: 13))
                            }
                            .foregroundColor(.red.opacity(0.9))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        }

                        // Continue button
                        Button(action: save) {
                            ZStack {
                                if isSaving {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Continue")
                                        .font(.custom("Poppins-SemiBold", size: 16))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                Group {
                                    if isSaving || trimmedUsername.isEmpty {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.white.opacity(0.1))
                                    } else {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        Color(red: 0.4, green: 0.6, blue: 0.9),
                                                        Color(red: 0.5, green: 0.7, blue: 0.95)
                                                    ],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .shadow(color: Color.cyan.opacity(0.4), radius: 20, x: 0, y: 10)
                                    }
                                }
                            )
                        }
                        .disabled(isSaving || trimmedUsername.isEmpty)
                    }
                    .padding(28)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 30)
                    .animation(.easeOut(duration: 0.8).delay(0.2), value: animateContent)
                }
                .padding(.horizontal, 32)

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            animateContent = true
            usernameFocused = true
        }
        .onChange(of: selectedPhoto) { _, _ in
            handlePhotoSelection()
        }
    }

    // MARK: - Profile Picture Section

    private var profilePictureSection: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let profileImage {
                        profileImage
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .padding(28)
                            .foregroundColor(.white.opacity(0.35))
                    }
                }
                .frame(width: 120, height: 120)
                .background(
                    Circle()
                        .fill(.white.opacity(0.05))
                )
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.2), .white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.4, green: 0.6, blue: 0.9),
                                            Color(red: 0.5, green: 0.7, blue: 0.95)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.cyan.opacity(0.4), radius: 8, x: 0, y: 4)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.6), lineWidth: 2)
                        )
                }
            }

            Text("Photo de profil (optionnelle)")
                .font(.custom("Poppins-Regular", size: 12))
                .foregroundColor(.white.opacity(0.4))
        }
    }

    // MARK: - Computed Properties

    private var trimmedUsername: String {
        username.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Actions

    private func handlePhotoSelection() {
        Task {
            guard let item = selectedPhoto,
                  let data = try? await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else {
                return
            }
            profileImage = Image(uiImage: uiImage)
        }
    }

    private func save() {
        Task {
            isSaving = true
            errorMessage = nil

            let name = trimmedUsername
            guard !name.isEmpty else {
                errorMessage = "Username requis."
                isSaving = false
                return
            }

            // TODO: upload de la photo non implémenté côté API — sera plugué plus tard.
            let success = await userStore.updateProfile(
                username: name,
                phoneNumber: nil,
                bio: nil,
                profilePicture: nil
            )

            if !success {
                errorMessage = userStore.error?.errorDescription ?? "Une erreur est survenue."
            }

            isSaving = false
        }
    }
}

#Preview {
    let userStore = UserStore()
    return ProfileSetupView()
        .environmentObject(userStore)
}
