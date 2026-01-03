//
//  SearchView.swift
//  jamly
//
//  Created by Alexandre Vandenbulcke on 12/12/2025.
//
import SwiftUI

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = SearchViewModel()
    
    @State private var searchText = ""
    @State private var searchHistory: [String] = SearchHistoryManager.shared.loadHistory()
    @State private var navigateToResults = false
    @State private var submittedSearch = ""
    
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
            ZStack {
                VStack {
                    Divider()
                    
                    // Content - Show immediate results or recent searches
                    if searchText.isEmpty {
                        // Recent Searches
                        RecentSearchesView(
                            searchHistory: $searchHistory,
                            onSelectHistory: { query in
                                searchText = query
                                submittedSearch = query
                                navigateToResults = true
                            }
                        )
                    } else {
                        // Immediate search results with live typing
                        LiveSearchResults(
                            searchText: searchText,
                            viewModel: viewModel,
                            onSelectUser: { user in
                                // Navigate to user profile or handle selection
                                print("Selected user: \(user.username)")
                            }
                        )
                    }
                    
                    Spacer()
                }
            }
            .navigationDestination(isPresented: $navigateToResults) {
                SearchResultsView(
                    searchQuery: submittedSearch,
                    searchHistory: $searchHistory
                )
            }
            .onChange(of: searchText) { oldValue, newValue in
                // Perform live search while typing (with debouncing)
                Task {
                    // Add a small delay to avoid too many API calls
                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                    
                    // Only search if the text hasn't changed again
                    if newValue == searchText && !newValue.isEmpty {
                        await viewModel.search(query: newValue)
                    } else if newValue.isEmpty {
                        viewModel.clearResults()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search", text: $searchText)
                            .foregroundStyle(.white)
                            .focused($isSearchFocused)
                            .submitLabel(.search)
                            .onSubmit {
                                if !searchText.isEmpty {
                                    if !searchHistory.contains(searchText) {
                                        searchHistory.insert(searchText, at: 0)
                                        SearchHistoryManager.shared.addToHistory(searchText)
                                    }
                                    submittedSearch = searchText
                                    navigateToResults = true
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
                    .frame(width: UIScreen.main.bounds.width - 100)
                }
            }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Live Search Results (shown while typing with pagination)
struct LiveSearchResults: View {
    let searchText: String
    @ObservedObject var viewModel: SearchViewModel
    let onSelectUser: (SearchUser) -> Void
    
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
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("Try searching for something else")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
            } else {
                // Results list with pagination
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.searchResults) { user in
                            UserSearchResultRow(user: user)
                                .onTapGesture {
                                    onSelectUser(user)
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
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding()
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - User Search Result Row
struct UserSearchResultRow: View {
    let user: SearchUser
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile picture or placeholder
            if let profilePicture = user.profilePicture, !profilePicture.isEmpty {
                AsyncImage(url: URL(string: profilePicture)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 20))
                    )
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(user.username)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                if let email = user.email {
                    Text(email)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

struct ImmediateResultRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let searchText: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.gray)
                .frame(width: 44, height: 44)
                .background(Color.gray.opacity(0.2))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

struct RecentSearchesView: View {
    @Binding var searchHistory: [String]
    let onSelectHistory: (String) -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Recent")
                        .foregroundStyle(Color.gray)
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    if !searchHistory.isEmpty {
                        Button("Clear All") {
                            searchHistory.removeAll()
                            SearchHistoryManager.shared.clearHistory()
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                if searchHistory.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No recent searches")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    ForEach(searchHistory, id: \.self) { query in
                        SearchHistoryRow(
                            query: query,
                            onTap: {
                                onSelectHistory(query)
                            },
                            onDelete: {
                                if let index = searchHistory.firstIndex(of: query) {
                                    searchHistory.remove(at: index)
                                    SearchHistoryManager.shared.removeFromHistory(query)
                                }
                            }
                        )
                    }
                }
            }
        }
    }
}

struct SearchHistoryRow: View {
    let query: String
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.gray)
                    .font(.system(size: 16))
                
                Text(query)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SearchView()
}
