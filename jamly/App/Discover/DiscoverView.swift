import SwiftUI

struct DiscoverView: View {
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 12) {
                Image(systemName: "timelapse")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("Coming soon...")
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        
//        ZStack(alignment: .top) {
//            ScrollView {
//                VStack(spacing: 0) {
//                    // GeometryReader pour tracker le scroll
//                    GeometryReader { geo in
//                        Color.clear
//                            .onChange(of: geo.frame(in: .global).minY) { oldValue, newValue in
//                                scrollOffset = -newValue
//                            }
//                    }
//                    .frame(height: 0)
//                    
//                    // Espace pour l'avatar
//                    Color.clear
//                        .frame(height: 200)
//                }
//            }
//            
//            // Avatar fixe qui se fait écraser
//            VStack(spacing: 0) {
//                let maxAvatarSize: CGFloat = 150
//                let minAvatarSize: CGFloat = 50
//                
//                
//                // Calcul de la taille
//                let avatarSize = min(maxAvatarSize, max(minAvatarSize, maxAvatarSize - scrollOffset))
//                
//                Image(systemName: "person.circle.fill")
//                    .resizable()
//                    .frame(width: avatarSize, height: avatarSize)
//                    .clipShape(Circle())
//
//                
//                Spacer()
//            }
//            .allowsHitTesting(false) // Important : permet de scroller à travers
    }
}



#Preview {
    DiscoverView()
}
