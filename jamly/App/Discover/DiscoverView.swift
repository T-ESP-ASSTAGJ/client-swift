import SwiftUI

struct DiscoverView: View {
    @StateObject private var viewModel = DiscoverViewModel()

    @State private var search: String = ""
    @State private var selectedPost: Post? = nil
    @State private var isShowingPostDetail = false

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    private var filteredPosts: [Post] {
        guard !search.isEmpty else { return viewModel.posts }
        return viewModel.posts.filter {
            $0.user.username.localizedCaseInsensitiveContains(search) ||
            $0.caption.localizedCaseInsensitiveContains(search) ||
            $0.track.title.localizedCaseInsensitiveContains(search) ||
            $0.track.artistName.localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.appBackground
                    .ignoresSafeArea()

                Image("jamly-pattern")
                    .resizable(resizingMode: .stretch)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        postsGrid
                    }
                }
            }
            .navigationTitle("Best influencers")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $search,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search..."
            )
            .navigationDestination(isPresented: $isShowingPostDetail) {
                if let post = selectedPost {
                    PostDetailView(post: post)
                }
            }
        }
        .onAppear {
            if viewModel.posts.isEmpty {
                viewModel.getFeedPublic()
            }
        }
    }

    // MARK: - Posts Grid

    private var postsGrid: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                loadingState()
            } else if filteredPosts.isEmpty {
                emptyState(message: search.isEmpty ? "No posts yet." : "No results for \"\(search)\".")
            } else {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(filteredPosts, id: \.id) { post in
                        gridItem(cover: post.backImage)
                            .onTapGesture {
                                selectedPost = post
                                isShowingPostDetail = true
                            }
                            .onAppear {
                                if search.isEmpty, post.id == viewModel.posts.last?.id {
                                    viewModel.loadMorePosts()
                                }
                            }
                    }

                    if viewModel.isLoadingMorePosts {
                        Color.clear
                            .gridCellColumns(3)
                            .overlay {
                                ProgressView()
                                    .scaleEffect(1.2)
                                    .tint(.white)
                            }
                            .frame(height: 60)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    // MARK: - Grid Item

    private func gridItem(cover: String) -> some View {
        GeometryReader { geo in
            ProfilePostThumbnail(imageURL: cover)
                .frame(width: geo.size.width, height: geo.size.width)
                .clipped()
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Empty State

    private func emptyState(message: String) -> some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 80)
            Text(message)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Loading State

    private func loadingState() -> some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 80)
            ProgressView()
                .tint(.white)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    DiscoverView()
}
