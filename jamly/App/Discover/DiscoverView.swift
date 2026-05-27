import SwiftUI

struct DiscoverView: View {
    @EnvironmentObject private var userStore: UserStore
    @StateObject private var viewModel = DiscoverViewModel()

    @State private var search: String = ""
    @State private var selectedPost: Post?

    private let spacing: CGFloat = 2

    private var visiblePosts: [Post] {
        guard let currentUserId = userStore.user?.id else { return viewModel.posts }
        return viewModel.posts.filter { $0.user.id != currentUserId }
    }

    private var filteredPosts: [Post] {
        guard !search.isEmpty else { return visiblePosts }
        let query = search
        return visiblePosts.filter {
            $0.user.username.localizedCaseInsensitiveContains(query) ||
            $0.caption.localizedCaseInsensitiveContains(query) ||
            $0.track.title.localizedCaseInsensitiveContains(query) ||
            $0.track.artistName.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                content
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $search,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search a user, track, artist…"
            )
            .navigationDestination(item: $selectedPost) { post in
                PostDetailView(post: post)
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
        .task {
            if viewModel.posts.isEmpty {
                viewModel.getFeedPublic()
            }
        }
    }

    // MARK: - Content

    private var content: some View {
        ScrollView {
            LazyVStack(spacing: spacing) {
                if viewModel.isLoading && viewModel.posts.isEmpty {
                    loadingState
                } else if let error = viewModel.errorMessage, viewModel.posts.isEmpty {
                    errorState(message: error)
                } else if filteredPosts.isEmpty {
                    if search.isEmpty {
                        EmptyStateView(
                            icon: "sparkles",
                            title: "Nothing to discover yet",
                            subtitle: "Posts from across Jamly will land here. Pull down to refresh."
                        )
                        .padding(.top, 80)
                    } else {
                        EmptyStateView(
                            icon: "magnifyingglass",
                            title: "No results",
                            subtitle: "Nothing matches \"\(search)\". Try a different keyword."
                        )
                        .padding(.top, 80)
                    }
                } else {
                    simpleGrid(posts: filteredPosts)
                }

                if viewModel.isLoadingMorePosts {
                    ProgressView()
                        .tint(.white)
                        .padding(.vertical, 16)
                }
            }
            .padding(.bottom, 24)
        }
    }

    // MARK: - Instagram-style grid

    private func simpleGrid(posts: [Post]) -> some View {
        let smallSize = (UIScreen.main.bounds.width - 2 * spacing) / 3
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: spacing),
            count: 3
        )
        return LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(posts, id: \.id) { post in
                tile(post: post, size: smallSize)
            }
        }
    }

    // MARK: - Tile

    private func tile(post: Post, size: CGFloat) -> some View {
        ProfilePostThumbnail(imageURL: post.backImage)
            .frame(width: size, height: size)
            .clipped()
            .overlay(alignment: .bottomLeading) {
                viewsBadge(count: post.viewsCount, large: size > 150)
                    .padding(size > 150 ? 10 : 6)
            }
            .contentShape(Rectangle())
            .onTapGesture { selectedPost = post }
            .onAppear {
                if search.isEmpty, post.id == viewModel.posts.last?.id {
                    viewModel.loadMorePosts()
                }
            }
    }

    private func viewsBadge(count: Int, large: Bool) -> some View {
        HStack(spacing: 3.5) {
            Image(systemName: "eye.fill")
                .font(.system(size: large ? 11 : 9, weight: .semibold))
            Text(formatCount(count))
                .font(.system(size: large ? 12 : 10, weight: .semibold))
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
    }

    private func formatCount(_ count: Int) -> String {
        switch count {
        case 1_000_000...:
            return String(format: "%.1fM", Double(count) / 1_000_000)
        case 1_000...:
            return String(format: "%.1fk", Double(count) / 1_000)
        default:
            return "\(count)"
        }
    }

    // MARK: - States

    private var loadingState: some View {
        ProgressView()
            .tint(.white)
            .padding(.top, 80)
            .frame(maxWidth: .infinity)
    }

    private func errorState(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                viewModel.getFeedPublic()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.top, 80)
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    DiscoverView()
}
