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
    @StateObject private var currentUserFollowingViewModel = FollowingViewModel() // Pour tracker qui on suit
    
    @State private var searchText = ""
    @State private var localFollowingState: [Int: Bool] = [:] // Track local follow state
    @State private var selectedUserId: Int? // ✅ Pour la navigation vers un profil
    
    // MARK: - Profile Mode
    /// Si userId est fourni, on affiche les following d'un autre utilisateur
    /// Sinon, on affiche les following de l'utilisateur connecté
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
        
        // Si c'est notre propre profil, on vérifie dans la liste affichée
        if isOwnProfile {
            return followingViewModel.followingUsers.contains(where: { $0.id == userId })
        } else {
            // Si c'est le profil d'un autre, on vérifie dans notre propre liste de following
            return currentUserFollowingViewModel.followingUsers.contains(where: { $0.id == userId })
        }
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
                        Text(isOwnProfile ? "You follow no one yet." : "This user follows no one.")
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
                    UserRow(
                        user: following,
                        isFollowing: isFollowing(userId: following.id),
                        showFollowBack: false,
                        showFollowButton: isOwnProfile,
                        onToggleFollow: {
                            await toggleFollow(for: following)
                        }
                    )
                    .onTapGesture {
                        selectedUserId = following.id
                    }
                    .onAppear {
                        if following.id == filteredFollowings.last?.id {
                            Task {
                                print("🚀 Dernier following atteint, chargement de la page suivante...")
                                await followingViewModel.loadMoreFollowing()
                            }
                        }
                    }
                }
                if followingViewModel.isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding(.vertical, 20)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Following")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search followers")
        .task {
            await followingViewModel.loadFollowing(userId: targetUserId)
            // Si ce n'est pas notre profil, charger aussi notre propre liste de following
            if !isOwnProfile {
                await currentUserFollowingViewModel.loadFollowing(userId: userStore.user?.id ?? 0)
            }
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
        .navigationDestination(item: $selectedUserId) { userId in
            ProfileView(userId: userId)
        }
    }
}
