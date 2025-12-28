//
//  FollowersView.swift
//  jamly
//
//  Created by REVERSS on 08/12/2025.
//

import SwiftUI

struct FollowersView: View {
    @EnvironmentObject private var userStore: UserStore
    
    @State private var searchText = ""
    
    var followers: [FollowedUser] {
        userStore.user?.follower ?? []
    }
    
    var filteredFollowers: [FollowedUser] {
        if searchText.isEmpty {
            return followers
        } else {
            return followers.filter { follower in
                follower.username.localizedStandardContains(searchText)
            }
        }
    }
    
    private func toggleFollow(for follower: FollowedUser) async {
        if userStore.isFollowing(userId: follower.id) {
            await userStore.unfollowUser(userId: follower.id)
        } else {
            await userStore.followUser(userId: follower.id)
        }
    }
    
    var body: some View {
        List(filteredFollowers) { follower in
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
                        Text(follower.username)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                Spacer()
                
                Button {
                    Task {
                        await toggleFollow(for: follower)
                    }
                } label: {
                    Text(userStore.isFollowing(userId: follower.id) ? "Unfollow" : "Follow back")
                }
                .buttonStyle(.glass)
            }
            .frame(height: 40)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 4, leading: 15, bottom: 20, trailing: 15))
        }
        
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .listStyle(.plain)
        .navigationTitle("Followers")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search followers")
    }
}
