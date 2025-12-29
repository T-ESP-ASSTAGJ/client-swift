import SwiftUI
import PhotosUI
import CoreLocation
import MusicKit
import Combine

struct CreatePostView: View {
    @EnvironmentObject var musicManager: MusicManager
    @StateObject private var viewModel = CreatePostViewModel()
    @State private var showSourceSheet = false
    @State private var showMusicPicker = false
    @State private var showImagePicker = false
    @State private var showBackImagePicker = false
    @State private var showCamera = false
    @State private var showBackCamera = false
    @State private var currentImageSelection: ImageSelection = .front
    
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
                        showMusicPicker = true
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
                        viewModel.publishPost()
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
                frontImage: $viewModel.frontImage,
                backImage: $viewModel.backImage
            )
            .environmentObject(musicManager)
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

// MARK: - View Model
class CreatePostViewModel: ObservableObject {
    @Published var frontImage: UIImage?
    @Published var backImage: UIImage?
    @Published var caption: String = ""
    @Published var selectedSong: Track?
    @Published var isPublishing = false
    

    
    var canPublish: Bool {
        frontImage != nil && backImage != nil && selectedSong != nil
    }
    
    func publishPost() {
        isPublishing = true
        
        print("📤 === PUBLISHING POST ===")
        print("🖼️ Front Image: \(frontImage != nil ? "✅ Set (\(Int(frontImage!.size.width))x\(Int(frontImage!.size.height)))" : "❌ None")")
        print("🖼️ Back Image: \(backImage != nil ? "✅ Set (\(Int(backImage!.size.width))x\(Int(backImage!.size.height)))" : "❌ None")")
        print("📝 Caption: \(caption.isEmpty ? "❌ Empty" : "\"\(caption)\"")")
        print("🎵 Song: \(selectedSong != nil ? "✅ \(selectedSong!.title) - \(selectedSong!.artistName)" : "❌ None")")
        print("📤 =========================")
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.isPublishing = false
            print("Post published!")
        }
    }
}

#Preview {
    NavigationStack {
        CreatePostView()
    }
}
