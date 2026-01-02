//
//  FollowersView.swift
//  jamly
//
//  Created by REVERSS on 08/12/2025.
//

import SwiftUI

struct FollowersView: View {
    @EnvironmentObject private var userStore: UserStore
    
    @StateObject private var followerViewModel = FollowerViewModel()
    @StateObject private var followingViewModel = FollowingViewModel()
    
    @State private var searchText = ""
    @State private var localFollowingState: [Int: Bool] = [:] // Track local follow state
    
    var filteredFollowers: [FollowerUser] {
        if searchText.isEmpty {
            return followerViewModel.followers
        } else {
            return followerViewModel.followers.filter { follower in
                follower.username.localizedStandardContains(searchText)
            }
        }
    }
    
    // Check if a user is locally followed
    private func isFollowing(userId: Int) -> Bool {
        // Si on a un état local (modification en cours), on l'utilise
        if let localState = localFollowingState[userId] {
            return localState
        }
        
        // Sinon, vérifier si l'utilisateur est dans notre liste de following
        return followingViewModel.followingUsers.contains(where: { $0.id == userId })
    }
    
    private func toggleFollow(for follower: FollowerUser) async {
        // Update local state immediately for UI
        let currentState = isFollowing(userId: follower.id)
        localFollowingState[follower.id] = !currentState
        
        // Perform API call
        if currentState {
            await userStore.unfollowUser(userId: follower.id, autoRefresh: false)
        } else {
            await userStore.followUser(userId: follower.id)
        }
    }
    
    var body: some View {
        Group {
            if followerViewModel.isLoading || followingViewModel.isLoading {
                // État de chargement
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading followers...")
                        .foregroundColor(.secondary)
                }
            }
            else if filteredFollowers.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    if searchText.isEmpty {
                        Text("You follow no one yet.")
                            .foregroundColor(.secondary)
                    } else {
                        Text("No user found with the name '\(searchText)'")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
            } else {
                List(filteredFollowers) { follower in
                    HStack(spacing: 8) {
                        // Image
                        HStack(spacing: 15) {
                            AsyncImage(url: URL(string: follower.profilePicture)) { phase in
                                Group {
                                    if let image = phase.image {
                                        image.resizable().scaledToFill()
                                    } else {
                                        Circle()
                                            .fill(Color.gray.opacity(0.2))
                                            .overlay(
                                                phase.error != nil ?
                                                Image(systemName: "person.fill").foregroundColor(.gray) as! ProgressView<EmptyView, EmptyView> :
                                                    ProgressView()
                                            )
                                    }
                                }
                                .frame(width: 44, height: 44)
                                .clipShape(Circle())
                            }

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
                            Text(isFollowing(userId: follower.id) ? "Unfollow" : "Follow back")
                        }
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
        .navigationTitle("Followers")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search followers")
        .task {
            await followerViewModel.loadFollowers(userId: userStore.user?.id ?? 0)
            await followingViewModel.loadFollowing(userId: userStore.user?.id ?? 0)
        }
        .onDisappear {
            Task {
                await userStore.fetchCurrentUser()
            }
        }
        .onAppear {
            localFollowingState.removeAll()
        }
    }
}
