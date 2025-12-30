//
//  SearchResults.swift
//  jamly
//
//  Created by Alexandre Vandenbulcke on 28/12/2025.
//
import SwiftUI

struct SearchResultsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SearchViewModel()
    let searchQuery: String
    @State private var searchText = ""
    @State private var selectedFilter: SearchFilter = .all
    @Binding var searchHistory: [String]
    @FocusState private var isSearchFocused: Bool
    
    enum SearchFilter: String, CaseIterable {
        case all = "All"
        case account = "Account"
        case artist = "Artist"
        case post = "Post"
        case music = "Music"
        
        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .account: return "person.crop.circle.fill"
            case .artist: return "music.mic"
            case .post: return "photo.on.rectangle"
            case .music: return "music.note"
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            VStack{
                HStack(spacing: 20) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                    }
                    
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search", text: $searchText)
                            .foregroundStyle(.white)
                            .focused($isSearchFocused)
                            .submitLabel(.search)
                            .onSubmit {
                                if !searchText.isEmpty && !searchHistory.contains(searchText) {
                                    searchHistory.insert(searchText, at: 0)
                                }
                            }
                        
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
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Filter Pills - Always visible on results page
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(SearchFilter.allCases, id: \.self) { filter in
                            FilterPill(
                                filter: filter,
                                isSelected: selectedFilter == filter,
                                action: {
                                    selectedFilter = filter
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                Divider()
                
                // Search Results - Now with real API data
                if selectedFilter == .account || selectedFilter == .all {
                    SearchResultsContent(
                        viewModel: viewModel,
                        searchText: searchText.isEmpty ? searchQuery : searchText,
                        selectedFilter: selectedFilter
                    )
                } else {
                    // Placeholder for other filter types
                    SearchResultsPage(
                        searchText: searchText.isEmpty ? searchQuery : searchText,
                        selectedFilter: selectedFilter
                    )
                }
                
                Spacer()
            }
        }
        .onAppear {
            searchText = searchQuery
            // Perform initial search
            Task {
                await viewModel.search(query: searchQuery)
            }
        }
        .onChange(of: searchText) { oldValue, newValue in
            // Perform search when text changes
            Task {
                // Add a small delay to avoid too many API calls
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                
                if newValue == searchText && !newValue.isEmpty {
                    await viewModel.search(query: newValue)
                }
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Filter Pill
struct FilterPill: View {
    let filter: SearchResultsView.SearchFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.system(size: 14))
                Text(filter.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? .white : .gray)
            .cornerRadius(20)
        }
    }
}

// MARK: - Search Results Content with Pagination
struct SearchResultsContent: View {
    @ObservedObject var viewModel: SearchViewModel
    let searchText: String
    let selectedFilter: SearchResultsView.SearchFilter
    
    var body: some View {
        ZStack {
            if viewModel.isLoading && viewModel.searchResults.isEmpty {
                // Initial loading state
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Searching...")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error {
                // Error state
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.red.opacity(0.7))
                    Text(error.errorDescription ?? "An error occurred")
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Try Again") {
                        Task {
                            await viewModel.search(query: searchText)
                        }
                    }
                    .foregroundColor(.blue)
                }
                .padding()
            } else if viewModel.searchResults.isEmpty && !viewModel.isLoading {
                // No results state
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
            } else {
                // Results list with pagination
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.searchResults) { user in
                            SearchResultUserCard(user: user, filterType: selectedFilter)
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
                    .padding()
                }
            }
        }
    }
}

// MARK: - Search Result User Card
struct SearchResultUserCard: View {
    let user: SearchUser
    let filterType: SearchResultsView.SearchFilter
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile picture
            if let profilePicture = user.profilePicture, !profilePicture.isEmpty {
                AsyncImage(url: URL(string: profilePicture)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 24))
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("@\(user.username)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                
                if let email = user.email {
                    Text(email)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .contentShape(Rectangle())
    }
}

struct SearchResultsPage: View {
    let searchText: String
    let selectedFilter: SearchResultsView.SearchFilter

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(0..<10, id: \.self) { index in
                    SearchResultCard(
                        title: "\(selectedFilter.rawValue) Result \(index + 1)",
                        subtitle: "Matching '\(searchText)'",
                        filterType: selectedFilter
                    )
                }
            }
            .padding()
        }
    }
}

struct SearchResultCard: View {
    let title: String
    let subtitle: String
    let filterType: SearchResultsView.SearchFilter
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: filterType.icon)
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}
