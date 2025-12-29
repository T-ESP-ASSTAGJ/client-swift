//
//  FollowersView.swift
//  jamly
//
//  Created by REVERSS on 08/12/2025.
//

import SwiftUI

struct FollowingView: View {
    @EnvironmentObject private var userStore: UserStore
    
    @State private var searchText = ""
    @State private var localFollowingState: [Int: Bool] = [:] // Track local follow state
    
    var followings: [FollowedUser] {
        userStore.user?.followed ?? []
    }
    
    var filteredFollowings: [FollowedUser] {
        if searchText.isEmpty {
            return followings
        } else {
            return followings.filter { following in
                following.username.localizedStandardContains(searchText)
            }
        }
    }
    
    // Check if a user is locally followed (or use server state if not modified)
    private func isFollowing(userId: Int) -> Bool {
        if let localState = localFollowingState[userId] {
            return localState
        }
        return userStore.isFollowing(userId: userId)
    }
    
    private func toggleFollow(for following: FollowedUser) async {
        // Update local state immediately for UI
        let currentState = isFollowing(userId: following.id)
        localFollowingState[following.id] = !currentState
        
        // Perform API call
        if currentState {
            await userStore.unfollowUser(userId: following.id, autoRefresh: false)
        } else {
            await userStore.followUser(userId: following.id)
        }
    }
    
    var body: some View {
        LazyVStack {
            if(followings.count == 0) {
                VStack(spacing: 12) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("You follow no one yet.")
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                List(filteredFollowings) { following in
                    HStack(spacing: 8) {
                        // Image
                        HStack(spacing: 15) {
                            Image("avatar1")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 44, height: 44)
                                .clipShape(Circle())
                            
                            // Infos
                            VStack(alignment: .leading, spacing: 4) {
                                Text(following.username)
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                        Spacer()
                        
                        Button {
                            Task {
                                await toggleFollow(for: following)
                            }
                        } label: {
                            Text(isFollowing(userId: following.id) ? "Unfollow" : "Follow")                }
                        .buttonStyle(.glass)
                    }
                    .frame(height: 40)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 15, bottom: 20, trailing: 15))
                    .scrollContentBackground(.hidden)
                    .listStyle(.plain)
                }
            }
        }
        
        .navigationTitle("Following")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search followers")
        .onDisappear {
            Task {
                await userStore.fetchCurrentUser()
            }
        }
        .onAppear {
            // Reset local state when view appears to sync with server
            localFollowingState.removeAll()
        }
    }
}
