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
    @State private var localFollowingState: [Int: Bool] = [:] // Track local follow state
    @State private var followers: [FollowerUser] = []
    @State private var followingUsers: [FollowingUser] = [] // Pour savoir qui on suit
    @State private var isLoading = true
    
    func loadFollowers() async {
        do {
            followers = try await FollowerAction.getFollowerUsers(
                page: 1,
                userId: userStore.user?.id ?? 0
            ).value
        } catch {
            print("Error during loading: \(error)")
            followers = []
        }
    }
    
    func loadFollowings() async {
        do {
            followingUsers = try await FollowingAction.getFollowingUsers(
                page: 1,
                userId: userStore.user?.id ?? 0
            ).value
        } catch {
            print("Error loading followings: \(error)")
            followingUsers = []
        }
    }
    
    var filteredFollowers: [FollowerUser] {
        if searchText.isEmpty {
            return followers
        } else {
            return followers.filter { follower in
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
        return followingUsers.contains(where: { $0.id == userId })
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
            if isLoading {
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
            isLoading = true
            await loadFollowers()
            await loadFollowings()
            isLoading = false
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
