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
    
    // MARK: - Profile Mode
    /// Si userId est fourni, on affiche les followers d'un autre utilisateur
    /// Sinon, on affiche les followers de l'utilisateur connecté
    let userId: Int?
    
    // MARK: - Computed Properties
    
    /// Indique si on affiche son propre profil
    private var isOwnProfile: Bool {
        guard let userId = userId, let currentUserId = userStore.user?.id else {
            return true // Par défaut, c'est notre profil
        }
        return userId == currentUserId
    }
    
    /// Retourne l'ID de l'utilisateur à afficher
    private var targetUserId: Int {
        return userId ?? userStore.user?.id ?? 0
    }
    
    // MARK: - Init
    
    init(userId: Int? = nil) {
        self.userId = userId
    }
    
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
            await userStore.unfollowUser(userId: follower.id, autoRefresh: true)
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
                    UserRow(
                        user: follower,
                        isFollowing: isFollowing(userId: follower.id),
                        showFollowBack: true,
                        showFollowButton: isOwnProfile,
                        onToggleFollow: {
                            await toggleFollow(for: follower)
                        }
                    )
                }
            }
        }
        .navigationTitle("Followers")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search followers")
        .task {
            await followerViewModel.loadFollowers(userId: targetUserId)
            // Charger la liste de following de l'utilisateur connecté pour savoir qui on suit
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
