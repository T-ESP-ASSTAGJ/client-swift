import SwiftUI

struct HomeFeed: View {
    @State private var currentIndex: Int? = 0
    let posts: [JamPost] = JamPost.mock
    
    var body: some View {
        ZStack(alignment: .top) {
            // ScrollView plein écran
            ScrollView {
                LazyVStack() {
                    ForEach(posts.indices, id: \.self) { index in
                        PostCard(post: posts[index])
                            .containerRelativeFrame(.vertical)
                            .offset(y: -50)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollPosition(id: $currentIndex)
            .scrollTargetBehavior(.paging)
            
            // Header en overlay
            
        }
    }
}

enum FeedSegment {
    case friends
    case discovery
}

#Preview {
    HomeFeed()
        .preferredColorScheme(ColorScheme.dark)
}
