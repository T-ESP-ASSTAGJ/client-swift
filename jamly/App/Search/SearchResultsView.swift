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
    @State private var selectedUserId: Int?
    @Binding var searchHistory: [String]
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        ZStack {
            VStack{
                if viewModel.isLoading && viewModel.searchResults.isEmpty {
                    LoadingStateView()
                } else {
                    SearchResultsList(
                        viewModel: viewModel,
                        searchText: searchText.isEmpty ? searchQuery : searchText,
                        onSelectUser: { user in
                            selectedUserId = user.id
                        },
                        cardStyle: .prominent
                    )
                }
                
                Spacer()
            }
        }
        .navigationDestination(item: $selectedUserId) { userId in
            ProfileView(userId: userId)
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


