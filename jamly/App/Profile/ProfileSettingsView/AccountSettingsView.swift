// AccountSettingsView.swift

import SwiftUI

struct AccountSettingsView: View {
    @EnvironmentObject private var userStore: UserStore
    @Environment(\.dismiss) private var dismiss

    @State private var username: String = ""
    @State private var email: String = ""
    @State private var showChangePassword = false
    @State private var showDeleteConfirmation = false

    private var user: User? { userStore.user }

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Personal Information")) {
                    HStack {
                        Text("Username")
                            .foregroundColor(.gray)
                        Spacer()
                        TextField("Username", text: $username)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color.white.opacity(0.05))

                    HStack {
                        Text("Email")
                            .foregroundColor(.gray)
                        Spacer()
                        TextField("Email", text: $email)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                }

                Section(header: Text("Security")) {
                    Button {
                        showChangePassword = true
                    } label: {
                        HStack {
                            Image(systemName: "lock")
                                .foregroundColor(.white)
                            Text("Change Password")
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                }

                Section {
                    Button {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Account")
                        }
                        .foregroundColor(.red)
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .navigationTitle("Account")
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
            .sheet(isPresented: $showChangePassword) {
                ChangePasswordView()
            }
            .alert("Delete Account", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    // call your API
                }
            } message: {
                Text("This action is permanent. All your data will be lost.")
            }
            .onAppear {
                username = user?.username ?? ""
                email = user?.email ?? ""
            }
        }
    }
}

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Current Password")) {
                    SecureField("Enter current password", text: $currentPassword)
                        .foregroundColor(.white)
                }
                .listRowBackground(Color.white.opacity(0.05))

                Section(header: Text("New Password")) {
                    SecureField("New password", text: $newPassword)
                        .foregroundColor(.white)
                    SecureField("Confirm new password", text: $confirmPassword)
                        .foregroundColor(.white)
                }
                .listRowBackground(Color.white.opacity(0.05))

                Section {
                    Button(action: savePassword) {
                        Text("Update Password")
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                    }
                    .listRowBackground(Color.white)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .navigationTitle("Change Password")
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
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func savePassword() {
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match."
            showError = true
            return
        }
        guard newPassword.count >= 8 else {
            errorMessage = "Password must be at least 8 characters."
            showError = true
            return
        }
        // call your API then dismiss()
    }
}
