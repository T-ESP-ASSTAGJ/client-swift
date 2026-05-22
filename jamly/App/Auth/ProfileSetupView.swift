import SwiftUI
import PhotosUI

struct ProfileSetupView: View {
    @EnvironmentObject private var userStore: UserStore

    @State private var step: SetupStep = .username
    @State private var username: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var selectedImageData: Data?
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var animateContent = false
    @FocusState private var usernameFocused: Bool

    enum SetupStep {
        case username
        case photo
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundLayer

                VStack(spacing: 0) {
                    Spacer()

                    Group {
                        switch step {
                        case .username:
                            usernameStepContent.transition(Self.slideTransition(edge: .leading))
                        case .photo:
                            photoStepContent.transition(Self.slideTransition(edge: .trailing))
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer()
                    Spacer()
                }
            }
            .toolbar {
                if step == .photo {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: goBackToUsernameStep) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .disabled(isSaving)
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { save(withPhoto: false) }) {
                            Text("Skip")
                                .font(.custom("Poppins-Medium", size: 15))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .disabled(isSaving)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarBackButtonHidden(true)
        }
        .dismissKeyboardOnTap()
        .onAppear {
            animateContent = true
            usernameFocused = true
        }
        .onChange(of: selectedPhoto) { _, _ in
            handlePhotoSelection()
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
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

            GeometryReader { geometry in
                ambientCircle(
                    colors: [Color.cyan.opacity(0.25), Color.blue.opacity(0.2)],
                    size: 280,
                    blur: 95,
                    offset: CGSize(width: -80, height: -30)
                )

                ambientCircle(
                    colors: [Color.purple.opacity(0.3), Color.pink.opacity(0.2)],
                    points: (.bottomLeading, .topTrailing),
                    size: 220,
                    blur: 85,
                    offset: CGSize(width: geometry.size.width - 120, height: geometry.size.height - 150),
                    delay: 0.2
                )
            }
        }
    }

    private func ambientCircle(
        colors: [Color],
        points: (start: UnitPoint, end: UnitPoint) = (.topLeading, .bottomTrailing),
        size: CGFloat,
        blur: CGFloat,
        offset: CGSize,
        delay: Double = 0
    ) -> some View {
        Circle()
            .fill(LinearGradient(colors: colors, startPoint: points.start, endPoint: points.end))
            .frame(width: size, height: size)
            .blur(radius: blur)
            .offset(x: offset.width, y: offset.height)
            .opacity(animateContent ? 1 : 0)
            .animation(.easeInOut(duration: 1.5).delay(delay), value: animateContent)
    }

    // MARK: - Step 1: Username

    private var usernameStepContent: some View {
        VStack(spacing: 28) {
            stepHeader(
                title: "Choose a username",
                subtitle: "This is how others will find you"
            )

            VStack(spacing: 20) {
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

                errorBanner

                continueButton(isEnabled: !trimmedUsername.isEmpty, action: goToPhotoStep)
            }
            .padding(10)
        }
    }

    // MARK: - Step 2: Photo

    private var photoStepContent: some View {
        VStack(spacing: 28) {
            stepHeader(
                title: "Add a profile picture",
                subtitle: "This helps others recognize you"
            )

            VStack(spacing: 20) {
                profilePictureSection

                errorBanner

                continueButton(
                    isLoading: isSaving,
                    isEnabled: selectedImageData != nil && !isSaving,
                    action: { save(withPhoto: true) }
                )
            }
            .padding(10)
        }
    }

    // MARK: - Shared building blocks

    private func stepHeader(title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.custom("Poppins-Bold", size: 36))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color(white: 0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .purple.opacity(0.3), radius: 20, x: 0, y: 10)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity)

            Text(subtitle)
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var errorBanner: some View {
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
    }

    private static let accentGradient = LinearGradient(
        colors: [
            Color(red: 0.6, green: 0.4, blue: 0.9),
            Color(red: 0.8, green: 0.4, blue: 0.7)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    private static let glassStrokeGradient = LinearGradient(
        colors: [.white.opacity(0.2), .white.opacity(0.05)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private static func slideTransition(edge: Edge) -> AnyTransition {
        let move = AnyTransition.move(edge: edge).combined(with: .opacity)
        return .asymmetric(insertion: move, removal: move)
    }

    private func continueButton(
        isLoading: Bool = false,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView().tint(.white)
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
                    if isEnabled {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Self.accentGradient)
                            .shadow(color: Color.purple.opacity(0.4), radius: 20, x: 0, y: 10)
                    } else {
                        RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.1))
                    }
                }
            )
        }
        .disabled(!isEnabled)
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
                .background(Circle().fill(.white.opacity(0.05)))
                .clipShape(Circle())
                .overlay(Circle().stroke(Self.glassStrokeGradient, lineWidth: 1))

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Self.accentGradient)
                                .shadow(color: Color.purple.opacity(0.4), radius: 8, x: 0, y: 4)
                        )
                        .overlay(Circle().stroke(Color.black.opacity(0.6), lineWidth: 2))
                }
            }

            Text(selectedImageData == nil ? "No photo selected" : "Photo selected")
                .font(.custom("Poppins-Regular", size: 12))
                .foregroundColor(.white.opacity(0.4))
        }
    }

    // MARK: - Helpers

    private var trimmedUsername: String {
        username.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Actions

    private func goToPhotoStep() {
        guard !trimmedUsername.isEmpty else {
            errorMessage = "Username required."
            return
        }
        errorMessage = nil
        usernameFocused = false
        withAnimation(.easeInOut(duration: 0.35)) {
            step = .photo
        }
    }

    private func goBackToUsernameStep() {
        errorMessage = nil
        withAnimation(.easeInOut(duration: 0.35)) {
            step = .username
        }
        usernameFocused = true
    }

    private func handlePhotoSelection() {
        Task { @MainActor in
            guard let item = selectedPhoto,
                  let data = try? await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else {
                return
            }
            profileImage = Image(uiImage: uiImage)
            selectedImageData = uiImage.jpegData(compressionQuality: 0.8)
        }
    }

    private func save(withPhoto: Bool) {
        Task {
            isSaving = true
            errorMessage = nil

            let name = trimmedUsername
            var profilePictureURI: String? = nil
            if withPhoto, let imageData = selectedImageData {
                profilePictureURI = "data:image/jpeg;base64,\(imageData.base64EncodedString())"
            }

            let success = await userStore.updateProfile(
                username: name,
                phoneNumber: nil,
                bio: nil,
                profilePicture: profilePictureURI
            )

            if !success {
                errorMessage = userStore.error?.errorDescription ?? "An error occurred."
            }

            isSaving = false
        }
    }
}
