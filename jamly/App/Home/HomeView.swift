import SwiftUI

enum FeedSegment {
    case friends
    case discovery
}

struct HomeView: View {
    @State private var showSearchView: Bool = false
    
    @Binding var selectedSegment: FeedSegment
    @Binding var discoveryScrollPosition: Int?
    @Binding var friendsScrollPosition: Int?
    
    init(
        selectedSegment: Binding<FeedSegment>,
        discoveryScrollPosition: Binding<Int?>,
        friendsScrollPosition: Binding<Int?>
    ) {
        self._selectedSegment = selectedSegment
        self._discoveryScrollPosition = discoveryScrollPosition
        self._friendsScrollPosition = friendsScrollPosition
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.appBackground
                .ignoresSafeArea()
            
            Image("jamly-pattern")
                .resizable(resizingMode: .stretch)
                .ignoresSafeArea()
            
            // Feed en dessous (prend tout l'écran)
            HomeFeed(
                selectedSegment: $selectedSegment,
                discoveryScrollPosition: $discoveryScrollPosition,
                friendsScrollPosition: $friendsScrollPosition
            )
            
            // Header au-dessus avec dégradé transparent
            Header(selectedSegment: $selectedSegment)
                .background(
                    LinearGradient(
                        colors: [.black.opacity(0.7), .black.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                )
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("JAMLY.")
                    .font(.custom("Poppins-BoldItalic", size: 18))
                    .italic()
                    .foregroundColor(.white)
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    showSearchView = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .padding(.trailing, 3)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showSearchView) {
            SearchView()
        }
    }
}
