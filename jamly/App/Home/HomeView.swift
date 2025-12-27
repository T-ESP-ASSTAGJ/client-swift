import SwiftUI

enum FeedSegment {
    case friends
    case discovery
}

struct HomeView: View {
    @Binding var selectedSegment: FeedSegment
    
    @Binding var scrollPosition: Int?  // ✅ Change en @Binding
    
    init(selectedSegment: Binding<FeedSegment>, scrollPosition: Binding<Int?>) {
        self._selectedSegment = selectedSegment
        self._scrollPosition = scrollPosition
    }
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            Image("jamly-pattern")
                .resizable(resizingMode: .stretch)
                .ignoresSafeArea()
            
            VStack {
                Header(selectedSegment: $selectedSegment)
                
                HomeFeed(scrollPosition: $scrollPosition, selectedSegment: $selectedSegment)
            }
        }
    }
}

