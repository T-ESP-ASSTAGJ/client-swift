import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            Image("jamly-pattern")
                .resizable(resizingMode: .stretch)
                .ignoresSafeArea()
            
            VStack {
                Header()
                
                HomeFeed()
            }
        }
    }
}

#Preview {
    HomeView()
}
