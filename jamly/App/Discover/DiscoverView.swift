import SwiftUI

struct DiscoverView: View {
    @StateObject private var viewModel = DiscoverViewModel()

    @State private var search: String = ""
    @State private var selectedPost: Post?

    private let spacing: CGFloat = 2

    private var filteredPosts: [Post] {
        guard !search.isEmpty else { return viewModel.posts }
        let query = search
        return viewModel.posts.filter {
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
                    emptyState(
                        message: search.isEmpty
                            ? "No posts yet."
                            : "No results for \"\(search)\"."
                    )
                } else if search.isEmpty {
                    mosaic(posts: filteredPosts)
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

    // MARK: - Instagram-style Mosaic

    /// Pattern par cycle de 6 posts:
    /// - 3 premiers : 1 tile large (2x2) + 2 small empilés (côté alterné)
    /// - 3 suivants : ligne classique de 3 small
    @ViewBuilder
    private func mosaic(posts: [Post]) -> some View {
        let totalWidth = UIScreen.main.bounds.width
        let smallSize = (totalWidth - 2 * spacing) / 3
        let largeSize = smallSize * 2 + spacing

        let chunks = posts.chunked(into: 6)

        ForEach(Array(chunks.enumerated()), id: \.offset) { index, chunk in
            let leftFeatured = index % 2 == 0

            featuredRow(
                chunk: chunk,
                leftFeatured: leftFeatured,
                smallSize: smallSize,
                largeSize: largeSize
            )

            if chunk.count > 3 {
                normalRow(
                    posts: Array(chunk.dropFirst(3)),
                    smallSize: smallSize
                )
            }
        }
    }

    @ViewBuilder
    private func featuredRow(
        chunk: [Post],
        leftFeatured: Bool,
        smallSize: CGFloat,
        largeSize: CGFloat
    ) -> some View {
        let large = chunk.first
        let small1 = chunk.count > 1 ? chunk[1] : nil
        let small2 = chunk.count > 2 ? chunk[2] : nil

        HStack(spacing: spacing) {
            if leftFeatured {
                if let large {
                    tile(post: large, size: largeSize)
                }
                VStack(spacing: spacing) {
                    if let small1 {
                        tile(post: small1, size: smallSize)
                    }
                    if let small2 {
                        tile(post: small2, size: smallSize)
                    }
                }
            } else {
                VStack(spacing: spacing) {
                    if let small1 {
                        tile(post: small1, size: smallSize)
                    }
                    if let small2 {
                        tile(post: small2, size: smallSize)
                    }
                }
                if let large {
                    tile(post: large, size: largeSize)
                }
            }
        }
        .frame(height: largeSize)
    }

    private func normalRow(posts: [Post], smallSize: CGFloat) -> some View {
        HStack(spacing: spacing) {
            ForEach(posts, id: \.id) { post in
                tile(post: post, size: smallSize)
            }
        }
    }

    // MARK: - Simple grid (search results)

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

    private func emptyState(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.list")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 80)
        .padding(.horizontal, 32)
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

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

#Preview {
    DiscoverView()
}
