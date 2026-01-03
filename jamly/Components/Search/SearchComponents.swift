//
//  SearchComponents.swift
//  jamly
//
//  Created by Jonathan Dumesnil on 03/01/2026.
//
import SwiftUI

// MARK: - Reusable Search Bar
struct SearchBarToolbarItem: View {
    @Binding var searchText: String
    @FocusState.Binding var isSearchFocused: Bool
    let onSubmit: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search", text: $searchText)
                .foregroundStyle(.white)
                .focused($isSearchFocused)
                .submitLabel(.search)
                .onSubmit(onSubmit)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .frame(width: UIScreen.main.bounds.width - 100)
    }
}

// MARK: - Reusable Search Results List with Pagination
struct SearchResultsList: View {
    @ObservedObject var viewModel: SearchViewModel
    let searchText: String
    let onSelectUser: ((SearchUser) -> Void)?
    var cardStyle: UserSearchResultCard.CardStyle = .default
    
    @EnvironmentObject private var userStore: UserStore
    @StateObject private var followingViewModel = FollowingViewModel()
    @State private var localFollowingState: [Int: Bool] = [:]
    
    private func toggleFollow(for user: SearchUser) async {
        // Update local state immediately for UI
        let currentState = localFollowingState[user.id] ?? followingViewModel.followingUsers.contains(where: { $0.id == user.id })
        localFollowingState[user.id] = !currentState
        
        // Perform API call
        if currentState {
            await userStore.unfollowUser(userId: user.id)
        } else {
            await userStore.followUser(userId: user.id)
        }
    }
    
    var body: some View {
        ZStack {
            if viewModel.isLoading && viewModel.searchResults.isEmpty {
                // Initial loading state
                LoadingStateView()
            } else if let error = viewModel.error {
                // Error state
                ErrorStateView(error: error) {
                    Task {
                        await viewModel.search(query: searchText)
                    }
                }
            } else if viewModel.searchResults.isEmpty && !viewModel.isLoading {
                // No results state
                EmptyResultsView()
            } else {
                // Results list with pagination
                ScrollView {
                    LazyVStack(spacing: cardStyle == .default ? 0 : 12) {
                        ForEach(viewModel.searchResults) { user in
                            UserSearchResultCard(
                                user: user,
                                localFollowingState: $localFollowingState,
                                followingUsers: followingViewModel.followingUsers,
                                onToggleFollow: toggleFollow,
                                style: cardStyle
                            )
                                .onTapGesture {
                                    onSelectUser?(user)
                                }
                                .onAppear {
                                    // Load more when approaching the end
                                    if viewModel.shouldLoadMore(for: user) {
                                        Task {
                                            await viewModel.loadMoreResults()
                                        }
                                    }
                                }
                        }
                        
                        // Loading indicator at the bottom
                        if viewModel.isLoadingMore {
                            LoadingMoreIndicator()
                        }
                    }
                    .padding(cardStyle == .prominent ? 16 : 0)
                }
            }
        }
        .task {
            // Load following list when view appears
            if let userId = userStore.user?.id {
                await followingViewModel.loadFollowing(userId: userId)
            }
        }
        .onAppear {
            localFollowingState.removeAll()
        }
    }
}

// MARK: - User Search Result Card (Unified)
struct UserSearchResultCard: View {
    let user: SearchUser
    @Binding var localFollowingState: [Int: Bool]
    let followingUsers: [FollowingUser]
    let onToggleFollow: (SearchUser) async -> Void
    var style: CardStyle = .default
    
    enum CardStyle {
        case `default`  // For SearchView (compact)
        case prominent  // For SearchResultsView (with background)
    }
    
    // Check if a user is locally followed
    private var isFollowing: Bool {
        if let localState = localFollowingState[user.id] {
            return localState
        }
        return followingUsers.contains(where: { $0.id == user.id })
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile picture
            if let profilePicture = user.profilePicture, !profilePicture.isEmpty {
                AsyncImage(url: URL(string: profilePicture)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    placeholderView
                }
                .frame(width: imageSize, height: imageSize)
                .clipShape(imageShape)
            } else {
                placeholderView
                    .frame(width: imageSize, height: imageSize)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: iconSize))
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(usernameText)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                if let email = user.email {
                    Text(email)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Button {
                Task {
                    await onToggleFollow(user)
                }
            } label: {
                Text(isFollowing ? "Unfollow" : "Follow")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .cornerRadius(8)
            }
            .buttonStyle(.glass)
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background(backgroundColor)
        .cornerRadius(cornerRadius)
        .contentShape(Rectangle())
    }
    
    // Style-dependent properties
    private var imageSize: CGFloat {
        style == .default ? 44 : 60
    }
    
    private var iconSize: CGFloat {
        style == .default ? 20 : 24
    }
    
    private var imageShape: some Shape {
        style == .default ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var placeholderView: some View {
        Group {
            if style == .default {
                Circle()
                    .fill(Color.gray.opacity(0.2))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
            }
        }
    }
    
    private var usernameText: String {
        style == .default ? user.username : "@\(user.username)"
    }
    
    private var horizontalPadding: CGFloat {
        style == .default ? 0 : 16
    }
    
    private var verticalPadding: CGFloat {
        style == .default ? 8 : 12
    }
    
    private var backgroundColor: Color {
        style == .default ? Color.clear : Color.gray.opacity(0.05)
    }
    
    private var cornerRadius: CGFloat {
        style == .default ? 0 : 12
    }
}

// Helper for shape type erasure
struct AnyShape: Shape {
    private let _path: (CGRect) -> Path
    
    init<S: Shape>(_ shape: S) {
        _path = { rect in
            shape.path(in: rect)
        }
    }
    
    func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}

// MARK: - Loading State View
struct LoadingStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Searching...")
                .foregroundColor(.gray)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Error State View
struct ErrorStateView: View {
    let error: AppError
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red.opacity(0.7))
            Text(error.errorDescription ?? "An error occurred")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Try Again") {
                onRetry()
            }
            .foregroundColor(.blue)
        }
        .padding()
    }
}

// MARK: - Empty Results View
struct EmptyResultsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))
            Text("No content found")
                .font(.headline)
                .foregroundColor(.white)
            Text("Try searching for something else")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Loading More Indicator
struct LoadingMoreIndicator: View {
    var body: some View {
        HStack {
            Spacer()
            ProgressView()
                .padding()
            Text("Loading more...")
                .foregroundColor(.gray)
                .font(.caption)
            Spacer()
        }
    }
}

// MARK: - Keyboard Helper Extension
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
