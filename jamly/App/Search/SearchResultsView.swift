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
    @State private var selectedUserId: Int?
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
            VStack{                
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
                
                // Search Results - Now with real API data and loading state
                if viewModel.isLoading && viewModel.searchResults.isEmpty {
                    // Show loading state during initial search
                    LoadingStateView()
                } else if selectedFilter == .account || selectedFilter == .all {
                    SearchResultsContent(
                        viewModel: viewModel,
                        searchText: searchText.isEmpty ? searchQuery : searchText,
                        selectedFilter: selectedFilter,
                        onSelectUser: { user in
                            selectedUserId = user.id
                        }
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
        .toolbar {
            ToolbarItem(placement: .principal) {
                SearchBarToolbarItem(
                    searchText: $searchText,
                    isSearchFocused: $isSearchFocused,
                    onSubmit: {
                        if !searchText.isEmpty && !searchHistory.contains(searchText) {
                            searchHistory.insert(searchText, at: 0)
                        }
                    }
                )
            }
        }
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
    let onSelectUser: (SearchUser) -> Void

    var body: some View {
        SearchResultsList(
            viewModel: viewModel,
            searchText: searchText,
            onSelectUser: nil,
            cardStyle: .prominent
        )
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
