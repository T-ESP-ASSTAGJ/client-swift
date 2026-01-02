//
//  FollowersView.swift
//  jamly
//
//  Created by REVERSS on 08/12/2025.
//

import SwiftUI

struct FollowingView: View {
    @EnvironmentObject private var userStore: UserStore
    
    @StateObject private var followingViewModel = FollowingViewModel()
    
    @State private var searchText = ""
    @State private var localFollowingState: [Int: Bool] = [:] // Track local follow state
    
    
    var filteredFollowings: [FollowingUser] {
        if searchText.isEmpty {
            return followingViewModel.followingUsers
        } else {
            return followingViewModel.followingUsers.filter { following in
                following.username.localizedStandardContains(searchText)
            }
        }
    }
    
    // Check if a user is locally followed (or use server state if not modified)
    private func isFollowing(userId: Int) -> Bool {
        // Si on a un état local (modification en cours), on l'utilise
        if let localState = localFollowingState[userId] {
            return localState
        }
        
        // Sinon, par défaut, si l'utilisateur est dans la liste des followings,
        // c'est qu'on le suit (puisque cette vue affiche justement la liste des following)
        return followingViewModel.followingUsers.contains(where: { $0.id == userId })
    }
    
    private func toggleFollow(for following: FollowingUser) async {
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
        Group {
            if followingViewModel.isLoading {
                // État de chargement
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading followers...")
                        .foregroundColor(.secondary)
                }
            }
            else if filteredFollowings.isEmpty {
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
                List(filteredFollowings) { following in
                    HStack(spacing: 8) {
                        // Image
                        HStack(spacing: 15) {
                            AsyncImage(url: URL(string: following.profilePicture)) { phase in
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
                            Text(isFollowing(userId: following.id) ? "Unfollow" : "Follow")
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
        .navigationTitle("Following")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search followers")
        .task {
            await followingViewModel.loadFollowing(userId: userStore.user?.id ?? 0)
        }
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
