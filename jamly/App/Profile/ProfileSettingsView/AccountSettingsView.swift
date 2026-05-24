// AccountSettingsView.swift

import SwiftUI
import PhotosUI

struct AccountSettingsView: View {
    @EnvironmentObject private var userStore: UserStore
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    @State private var username: String = ""
    @State private var phoneNumber: String = ""
    @State private var bio: String = ""
    @State private var profilePictureURL: String?
    
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: Image?
    
    @State private var isSaving = false
    @State private var showSavedMessage = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showDeleteConfirmation = false
    
    @State private var hasChanges = false
    
    enum Field: Hashable {
        case username
        case phoneNumber
        case bio
    }

    private var user: User? { userStore.user }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Picture Section
                    profilePictureSection
                    
                    // Editable Fields
                    VStack(spacing: 16) {
                        editableField(
                            title: "Username",
                            text: $username,
                            placeholder: "Enter username",
                            field: .username
                        )
                        
                        editableField(
                            title: "Phone Number",
                            text: $phoneNumber,
                            placeholder: "Enter phone number",
                            keyboardType: .phonePad,
                            field: .phoneNumber
                        )
                        
                        editableBioField()
                    }
                    .padding(.horizontal)
                    
                    // Save Button
                    if hasChanges || showSavedMessage {
                        Button(action: saveProfile) {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                } else if showSavedMessage {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Saved")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                } else {
                                    Text("Save Changes")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(showSavedMessage ? Color.green.opacity(0.1) : Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(12)
                        }
                        .disabled(isSaving || showSavedMessage)
                        .padding(.horizontal)
                    }
                    
                    // Delete Account Section
                    VStack(spacing: 16) {
                        Divider()
                            .background(Color.white.opacity(0.2))
                            .padding(.vertical, 8)
                        
                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Account")
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color.black)
            .contentShape(Rectangle())
            .onTapGesture {
                focusedField = nil
            }
            .navigationTitle("Edit Profile")
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
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("Delete Account", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteAccount()
                }
            } message: {
                Text("This action is permanent and cannot be undone. All your data will be deleted.")
            }
            .onAppear {
                loadUserData()
            }
            .onChange(of: username) { trackChanges() }
            .onChange(of: phoneNumber) { trackChanges() }
            .onChange(of: bio) { trackChanges() }
            .onChange(of: selectedPhoto) { handlePhotoSelection() }
        }
    }
    
    // MARK: - Profile Picture Section
    
    private var profilePictureSection: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                if let profileImage {
                    profileImage
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else {
                    AvatarView(profilePicture: profilePictureURL, size: 100)
                }
                
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Image(systemName: "camera.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                        .background(Circle().fill(Color.black))
                }
            }
            
            Text("Tap to change profile picture")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    
    // MARK: - Editable Fields
    
    private func editableField(
        title: String,
        text: Binding<String>,
        placeholder: String,
        keyboardType: UIKeyboardType = .default,
        field: Field
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            TextField(placeholder, text: text)
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .foregroundColor(.white)
                .keyboardType(keyboardType)
                .autocapitalization(keyboardType == .phonePad ? .none : .words)
                .focused($focusedField, equals: field)
                .submitLabel(.done)
                .onSubmit {
                    focusedField = nil
                }
        }
    }
    
    private func editableBioField() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Bio")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("\(bio.count)/300")
                    .font(.caption)
                    .foregroundColor(bio.count > 300 ? .red : .gray)
            }
            
            TextEditor(text: $bio)
                .frame(minHeight: 100)
                .padding(8)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .focused($focusedField, equals: .bio)
                .onChange(of: bio) { newValue in
                    if newValue.count > 300 {
                        bio = String(newValue.prefix(300))
                    }
                }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadUserData() {
        username = user?.username ?? ""
        phoneNumber = user?.phoneNumber ?? ""
        bio = user?.bio ?? ""
        profilePictureURL = user?.profilePicture
    }
    
    private func trackChanges() {
        hasChanges = username != (user?.username ?? "")
            || phoneNumber != (user?.phoneNumber ?? "")
            || bio != (user?.bio ?? "")
            || profileImage != nil
    }
    
    private func handlePhotoSelection() {
        Task {
            if let data = try? await selectedPhoto?.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                profileImage = Image(uiImage: uiImage)
                
                // Convert to base64 for API
                if let imageData = uiImage.jpegData(compressionQuality: 0.7) {
                    profilePictureURL = "data:image/jpeg;base64,\(imageData.base64EncodedString())"
                    trackChanges()
                }
            }
        }
    }
    
    private func saveProfile() {
        Task {
            isSaving = true
            
            let success = await userStore.updateProfile(
                username: username.isEmpty ? nil : username,
                phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
                bio: bio.isEmpty ? nil : bio,
                profilePicture: profileImage != nil ? profilePictureURL : nil
            )
            
            isSaving = false
            
            if success {
                hasChanges = false
                profileImage = nil
                
                // Show "Saved" message with animation
                withAnimation {
                    showSavedMessage = true
                }
                
                // Hide after 2 seconds
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    withAnimation {
                        showSavedMessage = false
                    }
                }
            } else {
                errorMessage = userStore.error?.errorDescription ?? "Failed to update profile"
                showErrorAlert = true
            }
        }
    }
    
    private func deleteAccount() {
        Task {
            let success = await userStore.deleteAccount()
            if success {
                // User is automatically logged out in deleteAccount()
                // Dismiss will happen automatically as user is no longer authenticated
                dismiss()
            } else {
                errorMessage = userStore.error?.errorDescription ?? "Failed to delete account"
                showErrorAlert = true
            }
        }
    }
}

