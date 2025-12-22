import SwiftUI
import PhotosUI
import CoreLocation
import MusicKit
import Combine

struct CreatePostView: View {
    @EnvironmentObject var musicManager: MusicManager
    @StateObject private var viewModel = CreatePostViewModel()
    @State private var showMusicPicker = false
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var showBackImagePicker = false
    @State private var showBackCamera = false
    @State private var currentImageSelection: ImageSelection = .front
    
    enum ImageSelection {
        case front, back
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            Color(hex: "0C0C0C")
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Images Section
                    HStack(spacing: 12) {
                        // Front Image
                        ImageSelectionCard(
                            title: "Photo principale",
                            image: viewModel.frontImage,
                            onCameraSelected: {
                                currentImageSelection = .front
                                showCamera = true
                            },
                            onGallerySelected: {
                                currentImageSelection = .front
                                showImagePicker = true
                            },
                            onRemove: {
                                viewModel.frontImage = nil
                            }
                        )
                        
                        // Back Image (BeReal style)
                        ImageSelectionCard(
                            title: "Photo arrière",
                            image: viewModel.backImage,
                            onCameraSelected: {
                                currentImageSelection = .back
                                showBackCamera = true
                            },
                            onGallerySelected: {
                                currentImageSelection = .back
                                showBackImagePicker = true
                            },
                            onRemove: {
                                viewModel.backImage = nil
                            }
                        )
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // Caption Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Description")
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(.white)
                        
                        ZStack(alignment: .topLeading) {
                            if viewModel.caption.isEmpty {
                                Text("Que se passe-t-il ?")
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
                                .frame(minHeight: 120)
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
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(viewModel.selectedSong?.title ?? "Ajouter une musique")
                                    .font(.custom("Poppins-SemiBold", size: 15))
                                    .foregroundColor(.white)
                                
                                if let artist = viewModel.selectedSong?.artistName {
                                    Text(artist)
                                        .font(.custom("Poppins-Regular", size: 13))
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(16)
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
                }
            }
            
            // Publish Button
            VStack {
                Spacer()
                
                Button(action: {
                    viewModel.publishPost()
                }) {
                    HStack {
                        if viewModel.isPublishing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Publier")
                                .font(.custom("Poppins-SemiBold", size: 17))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: viewModel.canPublish ?
                            [Color(hex: "FF6B9D"), Color(hex: "C44569")] :
                                [Color.gray.opacity(0.3), Color.gray.opacity(0.5)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: viewModel.canPublish ? Color(hex: "FF6B9D").opacity(0.3) : .clear, radius: 20, y: 10)
                }
                .disabled(!viewModel.canPublish || viewModel.isPublishing)
                .padding(.horizontal)
                .padding(.bottom, 60)
            }
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
        }
        .navigationTitle("Nouveau post")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $viewModel.frontImage)
        }
        .sheet(isPresented: $showCamera) {
            CameraView(image: $viewModel.frontImage)
        }
        .sheet(isPresented: $showBackImagePicker) {
            ImagePicker(image: $viewModel.backImage)
        }
        .sheet(isPresented: $showBackCamera) {
            CameraView(image: $viewModel.backImage)
        }
        .sheet(isPresented: $showMusicPicker) {
            MusicPickerView(selectedSong: $viewModel.selectedSong)
                .environmentObject(musicManager)
        }
    }
}

// MARK: - Image Selection Card
struct ImageSelectionCard: View {
    let title: String
    let image: UIImage?
    let onCameraSelected: () -> Void
    let onGallerySelected: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 220)
                        .clipped()
                        .cornerRadius(16)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 220)
                        .overlay(
                            VStack(spacing: 16) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.gray)
                                
                                Text(title)
                                    .font(.custom("Poppins-Medium", size: 13))
                                    .foregroundColor(.gray)
                            }
                        )
                }
                
                if image == nil {
                    VStack {
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Button(action: onCameraSelected) {
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                    )
                            }
                            
                            Button(action: onGallerySelected) {
                                Image(systemName: "photo.fill")
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
                        HStack {
                            Spacer()
                            Button(action: onRemove) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 24))
                                    .padding(8)
                                    .background(
                                        Circle()
                                            .fill(Color.black.opacity(0.5))
                                    )
                            }
                            .padding(8)
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
    @Published var selectedSong: Song?
    @Published var isPublishing = false
    
    var canPublish: Bool {
        frontImage != nil && !caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func publishPost() {
        isPublishing = true
        
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
