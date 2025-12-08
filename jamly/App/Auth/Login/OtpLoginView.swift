import SwiftUI

struct OtpLoginView: View {
    let email: String
    
    @State private var otpDigits: [String] = Array(repeating: "", count: 6)
    @FocusState private var focusedField: Int?
    @StateObject private var viewModel = LoginViewModel()
    @EnvironmentObject private var userStore: UserStore
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var animateContent = false
    @State private var resendCooldown: Int = 60
    @State private var canResend: Bool = false
    @State private var timer: Timer?
    
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
                
                VStack(spacing: 5) {
                    // Header
                    VStack(spacing: 12) {
                        VStack(spacing: 8) {
                            Text("Vérification")
                                .font(.custom("Poppins-Bold", size: 42))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, Color(white: 0.9)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .cyan.opacity(0.3), radius: 20, x: 0, y: 10)
                            
                            HStack(spacing: 5) {
                                Text("A verification code sent to")
                                    .font(.custom("Poppins-Regular", size: 14))
                                    .foregroundColor(.white.opacity(0.5))
                                
                                Text(email)
                                    .font(.custom("Poppins-Medium", size: 15))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : -20)
                    .animation(.easeOut(duration: 0.8), value: animateContent)
                    
                    // OTP Card
                    VStack(spacing: 24) {
                        // OTP Digits
                        HStack(spacing: 12) {
                            ForEach(0..<6, id: \.self) { index in
                                OTPDigitField(
                                    digit: $otpDigits[index],
                                    isFocused: focusedField == index,
                                    index: index
                                )
                                .focused($focusedField, equals: index)
                                .onChange(of: otpDigits[index]) { oldValue, newValue in
                                    handleDigitChange(at: index, oldValue: oldValue, newValue: newValue)
                                }
                                .onKeyPress(.delete) {
                                    handleDelete(at: index)
                                    return .handled
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        
                        // Error message
                        if let error = viewModel.errorMessage {
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
                        
                        // Resend button
                        Button(action: resendCode) {
                            if canResend {
                                Text("Resend code")
                                    .font(.custom("Poppins-Medium", size: 14))
                                    .foregroundColor(.white.opacity(0.8))
                            } else {
                                Text("Resend code in \(resendCooldown)s")
                                    .font(.custom("Poppins-Medium", size: 14))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                        .disabled(!canResend)
                        
                        // Verify button
                        Button(action: handleVerify) {
                            ZStack {
                                if viewModel.isLoading {
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
                                    if viewModel.isLoading || !fullCode.isValidOTP {
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
                        .disabled(viewModel.isLoading || !fullCode.isValidOTP)
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
        .onChange(of: viewModel.state) { _, newValue in
            if newValue == .success {
                handleAuthenticationSuccess()
            }
        }
        .onAppear {
            animateContent = true
            focusedField = 0
            startCooldownTimer()
        }
        .onDisappear {
            stopCooldownTimer()
        }
    }
    
    // MARK: - Computed Properties
    
    private var fullCode: String {
        otpDigits.joined()
    }
    
    // MARK: - Private Methods
    
    private func handleDigitChange(at index: Int, oldValue: String, newValue: String) {
        if newValue.count > 1 {
            let cleanedCode = newValue.filter { $0.isNumber }
            let digits = Array(cleanedCode.prefix(6))
            for (i, digit) in digits.enumerated() where i < 6 {
                otpDigits[i] = String(digit)
            }
            focusedField = min(digits.count, 5)
            return
        }
        
        if newValue.count > 1 {
            otpDigits[index] = String(newValue.suffix(1))
        }
        
        if !newValue.isEmpty && !newValue.allSatisfy({ $0.isNumber }) {
            otpDigits[index] = ""
            return
        }
        
        if !newValue.isEmpty && index < 5 {
            focusedField = index + 1
        }
    }
    
    private func handleDelete(at index: Int) {
        if otpDigits[index].isEmpty && index > 0 {
            otpDigits[index - 1] = ""
            focusedField = index - 1
        } else {
            otpDigits[index] = ""
        }
    }
    
    private func handleVerify() {
        viewModel.verify(email: email, code: fullCode)
    }
    
    private func resendCode() {
        guard canResend else { return }
        viewModel.request(email: email)
        canResend = false
        resendCooldown = 60
        startCooldownTimer()
    }
    
    private func startCooldownTimer() {
        stopCooldownTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if resendCooldown > 0 {
                resendCooldown -= 1
            } else {
                canResend = true
                stopCooldownTimer()
            }
        }
    }
    
    private func stopCooldownTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func handleAuthenticationSuccess() {
        Task {
            await userStore.fetchCurrentUser()
            authManager.isAuthenticated = true
            dismiss()
        }
    }
}

// MARK: - OTP Digit Field
struct OTPDigitField: View {
    @Binding var digit: String
    let isFocused: Bool
    let index: Int
    
    var body: some View {
        TextField("", text: $digit)
            .font(.custom("Poppins-Bold", size: 24))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .keyboardType(.numberPad)
            .frame(width: 48, height: 56)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(isFocused ? 0.1 : 0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isFocused ?
                                LinearGradient(
                                    colors: [Color.cyan, Color.blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                    LinearGradient(
                                        colors: [.white.opacity(0.2), .white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                lineWidth: isFocused ? 2 : 1
                            )
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
            .textContentType(.oneTimeCode)
    }
}

#Preview {
    let userStore = UserStore()
    let authManager = AuthManager(userStore: userStore)
    
    return NavigationStack {
        OtpLoginView(email: "john@doe.fr")
            .environmentObject(authManager)
            .environmentObject(userStore)
    }
}
