import SwiftUI
import PhotosUI
import CoreLocation
import MusicKit
import Combine

struct CreatePostView: View {
    @EnvironmentObject var musicManager: MusicManager
    @EnvironmentObject var userStore: UserStore
    @StateObject private var viewModel = CreatePostViewModel()
    @State private var showSourceSheet = false
    @State private var showMusicPicker = false
    @State private var showMusicAuthAlert = false
    @State private var showImagePicker = false
    @State private var showBackImagePicker = false
    @State private var showCamera = false
    @State private var showBackCamera = false
    @State private var currentImageSelection: ImageSelection = .front
    @Binding var selectedTab: TabItem
    
    enum ImageSelection {
        case front, back
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 24) {
                    ZStack(alignment: .top) {
                        // IMAGE PRINCIPALE AVEC BOUTON PAUSE CENTRÉ
                        ZStack {
                            ZStack {
                                ImageSelectionCard(
                                    image: viewModel.frontImage,
                                    onShowSourceSelection: {
                                        currentImageSelection = .front
                                        showSourceSheet = true
                                    },
                                    onRemove: {
                                        viewModel.frontImage = nil
                                    },
                                    frontImage: true
                                )
                            }
                            .opacity(0.8)
                        }
                        .frame(width: 370, height: 300)
                        
                        HStack(alignment: .top) {
                            Spacer()
                            
                            // 👉 BOUTON MINIATURE DROITE
                            ZStack {
                                ZStack{
                                    ImageSelectionCard(
                                        image: viewModel.backImage,
                                        onShowSourceSelection: {
                                            currentImageSelection = .back
                                            showSourceSheet = true
                                        },
                                        onRemove: {
                                            viewModel.backImage = nil
                                        },
                                        frontImage: false
                                    )
                                }
                                .frame(width: 80, height: 80)
                            }
                            .padding(.top, 15)
                            .padding(.horizontal, 15)
                        }
                        .frame(width: 370)
                    }
                    
                    // Caption Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Caption")
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(.white)
                        
                        ZStack(alignment: .topLeading) {
                            if viewModel.caption.isEmpty {
                                Text("What's up?")
                                    .font(.custom("Poppins-Regular", size: 15))
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                            }
                            
                            TextEditor(text: $viewModel.caption)
                                .font(.custom("Poppins-Regular", size: 15))
                                .foregroundColor(.white)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)
                    
                    // Music Selection
                    Button(action: {
                        Task { await handleMusicTap() }
                    }) {
                        HStack {
                            if let selectedSong = viewModel.selectedSong {
                                // Affichage de la chanson sélectionnée
                                if let artwork = selectedSong.artwork {
                                    ArtworkImage(artwork, width: 45, height: 45)
                                        .cornerRadius(6)
                                } else {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 45, height: 45)
                                        .overlay(
                                            Image(systemName: "music.note")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.5))
                                        )
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(selectedSong.title)
                                        .font(.custom("Poppins-SemiBold", size: 15))
                                        .foregroundColor(.white)
                                }
                            } else {
                                // État par défaut (aucune chanson)
                                Image(systemName: "music.note")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color(hex: "FF6B9D"), Color(hex: "C44569")],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Add a music")
                                        .font(.custom("Poppins-SemiBold", size: 15))
                                        .foregroundColor(.white)
                                    
                                    Text("Choose from your library")
                                        .font(.custom("Poppins-Regular", size: 13))
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)

                    // Publish Button
                    Button(action: {
                        Task {
                            let success = await viewModel.publishPost(userStore: userStore)
                            if success {
                                // ✅ Retour au tab Home
                                selectedTab = .home
                            }
                        }
                    }) {
                        HStack {
                            if viewModel.isPublishing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Publish")
                                    .font(.custom("Poppins-SemiBold", size: 17))
                                    .foregroundColor(viewModel.canPublish ? .black : .white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(viewModel.canPublish ? .white : Color.gray.opacity(0.35))
                        .cornerRadius(16)
                        .shadow(color: viewModel.canPublish ? .white.opacity(0.3) : .clear, radius: 20, y: 10)
                    }
                    .disabled(!viewModel.canPublish || viewModel.isPublishing)
                    .padding(.horizontal)
                    .padding(.vertical, 20)
                }
            }
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
        }
        .navigationTitle("New Post")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSourceSheet) {
            ImageSourceSheet(
                onCameraSelected: {
                    showSourceSheet = false
                    if(currentImageSelection == .front) {
                        showCamera = true
                    }else {
                        showBackCamera = true
                    }
                },
                onGallerySelected: {
                    showSourceSheet = false
                    if(currentImageSelection == .front) {
                        showImagePicker = true
                    }else {
                        showBackImagePicker = true
                    }
                }
            )
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $viewModel.frontImage)
        }
        .sheet(isPresented: $showCamera) {
            CameraView(image: $viewModel.frontImage)
                .ignoresSafeArea(.all)
        }
        .sheet(isPresented: $showBackImagePicker) {
            ImagePicker(image: $viewModel.backImage)
        }
        .sheet(isPresented: $showBackCamera) {
            CameraView(image: $viewModel.backImage)
                .ignoresSafeArea(.all)
        }
        .sheet(isPresented: $showMusicPicker) {
            MusicPickerView(
                selectedSong: $viewModel.selectedSong,
                selectedCatalogID: $viewModel.selectedCatalogId,
                frontImage: $viewModel.frontImage,
                backImage: $viewModel.backImage
            )
            .environmentObject(musicManager)
        }
        .alert("Connecte Apple Music", isPresented: $showMusicAuthAlert) {
            Button("Ouvrir les réglages") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Annuler", role: .cancel) {
                // Ferme l'alerte sans action : l'utilisateur reste sur l'écran de création.
            }
        } message: {
            Text("Pour ajouter une musique à ton post, autorise l'accès à Apple Music dans les réglages. Aucun abonnement n'est nécessaire.")
        }
    }

    // MARK: - Music Authorization Gate

    /// Ouvre le picker musique uniquement si Apple Music est autorisé.
    ///
    /// - `.notDetermined` : demande l'autorisation (prompt système, gratuit), puis ouvre
    ///   le picker si accordée.
    /// - `.authorized` : ouvre directement le picker.
    /// - `.denied`/`.restricted` : invite à activer l'accès dans les réglages.
    ///
    /// La recherche catalogue (donc le choix d'un morceau) fonctionne dès l'autorisation,
    /// sans abonnement Apple Music.
    private func handleMusicTap() async {
        switch musicManager.authorizationStatus {
        case .authorized:
            showMusicPicker = true
        case .notDetermined:
            await musicManager.requestAuthorization()
            if musicManager.authorizationStatus == .authorized {
                showMusicPicker = true
            } else {
                showMusicAuthAlert = true
            }
        default:
            showMusicAuthAlert = true
        }
    }
}

// MARK: - Image Selection Card
struct ImageSelectionCard: View {
    let image: UIImage?
    let onShowSourceSelection: () -> Void
    let onRemove: () -> Void
    let frontImage: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: frontImage ? 370 : 80, height: frontImage ? 300 : 80)
                        .clipped()
                        .cornerRadius(25)
                } else {
                    RoundedRectangle(cornerRadius: frontImage ? 25 : 20)
                        .stroke(Color.white.opacity(0.25), lineWidth: 2)
                        .overlay(
                            Image(systemName: "camera")
                                .font(.system(size: frontImage ? 36 : 20, weight: .semibold))
                                .contentTransition(.symbolEffect(.replace))
                                .foregroundStyle(.white.opacity(0.6))
                                .shadow(color: .white.opacity(0.6), radius: 4, x: 0, y: 0)
                                .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 4)
                        )
                }
                
                if image == nil {
                    VStack {
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Button(action: onShowSourceSelection) {
                                Image(systemName: "photo.badge.plus")
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                    )
                            }
                        }
                        .padding(.bottom, 16)
                    }
                } else {
                    VStack {
                        if !frontImage {
                            Spacer()
                        }
                        
                        HStack {
                            if !frontImage {
                                Spacer()
                            }
                            
                            Button(action: onRemove) {
                                Image(systemName: "xmark.circle.fill")
                                    .contentTransition(.symbolEffect(.replace))
                                    .foregroundStyle(.white.opacity(0.8))
                                    .shadow(color: .white.opacity(0.6), radius: 4, x: 0, y: 0)
                                    .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 4)
                                    .font(.system(size: 24))
                                    .padding(8)
                            }
                            .padding(8)
                            
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }
        }
    }
}

class CreatePostViewModel: ObservableObject {
    @Published var frontImage: UIImage?
    @Published var backImage: UIImage?
    @Published var caption: String = ""
    @Published var selectedSong: Song?
    @Published var selectedCatalogId: String?
    @Published var location: String = "Paris"
    @Published var isPublishing = false
    @Published var errorMessage: String?
    
    var canPublish: Bool {
        frontImage != nil && backImage != nil && selectedSong != nil && !caption.isEmpty
    }
    
    // MARK: - Image to Base64 Conversion
    private func imageToBase64(_ image: UIImage) -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return nil }
        let base64String = imageData.base64EncodedString()
        // Add data URI prefix that the backend ImageService expects
        return "data:image/jpeg;base64,\(base64String)"
    }
    
    private func artworkToBase64(artwork: Artwork, width: Int = 36, height: Int = 36) async -> String? {
        guard let url = artwork.url(width: width, height: height) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let base64 = data.base64EncodedString()
            return "data:image/jpeg;base64,\(base64)"
        } catch {
            print("❌ Erreur téléchargement artwork: \(error)")
            return nil
        }
    }

    
    // MARK: - Publish Post
    @MainActor func publishPost(userStore: UserStore) async -> Bool {
        guard canPublish else {
            errorMessage = "Veuillez remplir tous les champs requis"
            return false
        }
        
        guard let song = selectedSong,
              let frontBase64 = imageToBase64(frontImage!),
              let backBase64 = imageToBase64(backImage!)
        else {
            errorMessage = "Erreur lors de la conversion des images"
            return false
        }
        
        let catalogId = selectedCatalogId ?? song.id.rawValue
        print("🎵 Utilisation de l'ID catalogue: \(catalogId)")
        
        // Artwork géré séparément (car optionnel)
        let coverBase64: String
        if let artwork = song.artwork {
            coverBase64 = await artworkToBase64(artwork: artwork) ?? ""
        } else {
            coverBase64 = ""
        }
        
        isPublishing = true
        errorMessage = nil
        
        logPublishingDetails(frontBase64, backBase64)
        
        let trackInput = CreatePostRequest.TrackInput(
            songId: catalogId,
            title: song.title,
            artistName: song.artistName,
            releaseYear: getYear(from: song.releaseDate),
            coverImage: coverBase64
        )
        
        let request = CreatePostRequest(
            caption: caption,
            track: trackInput,
            frontImage: frontBase64,
            backImage: backBase64,
            location: location
        )
        
        do {
            _ = try await PostActions.create(post: request)
            
            // ✅ Rafraîchir le feed discovery (public)
            await userStore.loadFeed(page: 1, forceRefresh: true, mode: "public")
            
            // Reset le formulaire
            resetForm()
            
            isPublishing = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isPublishing = false
            return false
        }
    }
    
    // MARK: - Helper Methods
    private func getYear(from date: Date?) -> Int {
        guard let date = date else { return Calendar.current.component(.year, from: Date()) }
        return Calendar.current.component(.year, from: date)
    }
    
    private func resetForm() {
        frontImage = nil
        backImage = nil
        caption = ""
        selectedSong = nil
        location = ""
    }
    
    private func logPublishingDetails(_ frontBase64: String, _ backBase64: String) {
        print("📤 === PUBLISHING POST ===")
        print("🖼️ Front Image: ✅ Base64 with data URI prefix (\(frontBase64.count) chars)")
        print("🖼️ Back Image: ✅ Base64 with data URI prefix (\(backBase64.count) chars)")
        print("📝 Caption: \"\(caption)\"")
        if let song = selectedSong {
            let originalId = song.id.rawValue
            let catalogId = selectedCatalogId ?? originalId
            print("🎵 Song: \(song.title) - \(song.artistName)")
            print("   📀 Original ID: \(originalId)")
            print("   🌍 Catalog ID: \(catalogId)")
            print("   ✅ Type: \(catalogId.hasPrefix("i.") ? "Bibliothèque (sera converti)" : "Catalogue universel")")
        }
        print("📍 Location: \(location.isEmpty ? "Non défini" : location)")
        print("📤 =========================")
    }
}

#Preview {
    NavigationStack {
        CreatePostView(selectedTab: .constant(.create))
            .environmentObject(UserStore())
            .environmentObject(MusicManager())
    }
}
