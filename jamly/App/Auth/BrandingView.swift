//
//  BrandingView.swift
//  jamly
//
//  Created by REVERSS on 07/12/2025.
//


import SwiftUI

struct BrandingView: View {
    @State private var animateContent = false
    @State private var showLogin = false
    @State private var showRegister = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background avec image ou gradient
                GeometryReader { geometry in
                    // Image de fond (remplace par ton image)
                    Color.black
                        .overlay(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.7),
                                    Color.black.opacity(0.4),
                                    Color.black.opacity(0.8)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .ignoresSafeArea()
                    
                    // Circles d'ambiance
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.4), Color.pink.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 400, height: 400)
                        .blur(radius: 120)
                        .offset(x: -100, y: 100)
                        .opacity(animateContent ? 1 : 0)
                        .animation(.easeInOut(duration: 2), value: animateContent)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.3), Color.cyan.opacity(0.2)],
                                startPoint: .bottomLeading,
                                endPoint: .topTrailing
                            )
                        )
                        .frame(width: 350, height: 350)
                        .blur(radius: 100)
                        .offset(x: geometry.size.width - 150, y: geometry.size.height - 400)
                        .opacity(animateContent ? 1 : 0)
                        .animation(.easeInOut(duration: 2).delay(0.3), value: animateContent)
                }
                
                // Contenu principal
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Titre et description
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading) {
                            Text("Bienvenue sur")
                                .font(.custom("Poppins-Regular", size: 18))
                                .foregroundColor(.white.opacity(0.8))
                                .tracking(1)
                                .offset(y: 15)
                                .offset(x: 4)
                            
                            Text("JAMLY")
                                .font(.custom("Poppins-Bold", size: 62))
                                .fontWeight(.heavy)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, Color(white: 0.95)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .purple.opacity(0.4), radius: 30, x: 0, y: 15)
                        }
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : -30)
                        .animation(.easeOut(duration: 1), value: animateContent)
                        
                        Text("Explore les nouvelles découvertes musicales\nde tes amis, et partage leur ton mood.")
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(.white.opacity(0.7))
                            .lineSpacing(6)
                            .multilineTextAlignment(.leading)
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 20)
                            .animation(.easeOut(duration: 1).delay(0.3), value: animateContent)
                    }
                    .padding(.bottom, 60)
                    
                    // Boutons
                    VStack(spacing: 16) {
                        // Bouton Rejoindre
                        Button {
                            showRegister = true
                        } label: {
                            Text("Rejoindre")
                                .font(.custom("Poppins-SemiBold", size: 17))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 28)
                                        .fill(.white)
                                        .shadow(color: .white.opacity(0.3), radius: 20, x: 0, y: 10)
                                )
                        }
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 30)
                        .animation(.easeOut(duration: 1).delay(0.5), value: animateContent)
                        
                        // Texte "Tu as déjà un compte"
                        HStack(spacing: 6) {
                            Text("Tu as déjà un compte?")
                                .font(.custom("Poppins-Regular", size: 15))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Button {
                                showLogin = true
                            } label: {
                                Text("Connexion")
                                    .font(.custom("Poppins-SemiBold", size: 15))
                                    .foregroundColor(.white)
                                    .underline()
                            }
                        }
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)
                        .animation(.easeOut(duration: 1).delay(0.7), value: animateContent)
                    }
                    .padding(.bottom, 60)
                }
            }
            .padding(.horizontal, 24)
            .navigationDestination(isPresented: $showLogin) {
                LoginView()
            }
        
            .onAppear {
                animateContent = true
            }
        }
    }
}

#Preview("Branding") {
    BrandingView()
}
