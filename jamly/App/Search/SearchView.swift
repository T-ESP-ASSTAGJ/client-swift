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
                    SearchBarToolbarItem(
                        searchText: $searchText,
                        isSearchFocused: $isSearchFocused,
                        onSubmit: {
                            if !searchText.isEmpty {
                                if !searchHistory.contains(searchText) {
                                    searchHistory.insert(searchText, at: 0)
                                    SearchHistoryManager.shared.addToHistory(searchText)
                                }
                                submittedSearch = searchText
                                navigateToResults = true
                            }
                        }
                    )
                }
            }
    }
}

// MARK: - Live Search Results (shown while typing with pagination)
struct LiveSearchResults: View {
    let searchText: String
    @ObservedObject var viewModel: SearchViewModel
    let onSelectUser: (SearchUser) -> Void
    
    var body: some View {
        SearchResultsList(
            viewModel: viewModel,
            searchText: searchText,
            onSelectUser: onSelectUser
        )
        .padding(.horizontal, 16)
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
