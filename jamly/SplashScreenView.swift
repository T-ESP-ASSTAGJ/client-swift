import SwiftUI

struct SplashScreenView: View {
    @State private var animateContent = false
    
    var body: some View {
        ZStack {
            // Fond #0C0C0C
            Color.appBackground
                .ignoresSafeArea()
            
            // Pattern en arrière-plan
            Image("jamly-pattern")
                .resizable(resizingMode: .stretch)
                .ignoresSafeArea()
            
            // Logo
            Text("JAMLY.")
                .font(.custom("Poppins-BoldItalic", size: 70))
                .italic()
                .foregroundColor(.white)
                .tracking(-5)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 40)
                .animation(.easeOut(duration: 0.8), value: animateContent)
            
        }
        .onAppear {
            animateContent = true
        }
        .onDisappear {
            animateContent = false
        }
    }
}

#Preview {
    SplashScreenView()
}
