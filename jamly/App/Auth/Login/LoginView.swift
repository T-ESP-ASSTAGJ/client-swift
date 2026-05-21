import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var navigateToOtp = false
    @StateObject private var viewModel = LoginViewModel()
    
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var userStore: UserStore
    
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
                            colors: [Color.purple.opacity(0.3), Color.pink.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 300, height: 300)
                    .blur(radius: 100)
                    .offset(x: -100, y: -50)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.25), Color.cyan.opacity(0.2)],
                            startPoint: .bottomLeading,
                            endPoint: .topTrailing
                        )
                    )
                    .frame(width: 250, height: 250)
                    .blur(radius: 90)
                    .offset(x: geometry.size.width - 150, y: geometry.size.height - 200)
            }
            
            // Main content
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 32) {
                    // Logo
                    VStack() {
                        Text("Welcome to")
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(2)
                        
                        Text("JAMLY.")
                            .font(.custom("Poppins-MediumItalic", size: 50))
                            .fontWeight(.heavy)
                            .italic()
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, Color(white: 0.9)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .purple.opacity(0.3), radius: 20, x: 0, y: 10)
                            .offset(y: -15)
                    }

                    // Card
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.custom("Poppins-Regular", size: 15))
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(0.5)
                            
                            TextField("", text: $email, prompt: Text("\("john@doe.com")")
                                .foregroundColor(.white.opacity(0.3)))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                            .textContentType(nil)
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(.white)
                            .tint(.white)
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
                        
                        if let error = viewModel.errorMessage {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.caption)
                                Text(error)
                                    .font(.custom("Poppins-Regular", size: 13))
                            }
                            .foregroundColor(.red.opacity(0.9))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        }
                        
                        Button {
                            viewModel.request(email: email)
                        } label: {
                            ZStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    HStack(spacing: 12) {
                                        Text("Continue")
                                            .font(.custom("Poppins-SemiBold", size: 16))
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                Group {
                                    if viewModel.isLoading || !email.isValidEmail {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.white.opacity(0.1))
                                    } else {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        Color(red: 0.6, green: 0.4, blue: 0.9),
                                                        Color(red: 0.8, green: 0.4, blue: 0.7)
                                                    ],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .shadow(color: Color.purple.opacity(0.4), radius: 20, x: 0, y: 10)
                                    }
                                }
                            )
                        }
                        .disabled(viewModel.isLoading || !email.isValidEmail)
                    }
                    .padding(10)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .navigationDestination(isPresented: $navigateToOtp) {
            OtpLoginView(email: email)
        }
        .onChange(of: viewModel.state) { _, newState in
            if newState == .codeSent {
                navigateToOtp = true
            }
        }
    }
}
