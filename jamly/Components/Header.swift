//
//  Header.swift
//  jamly
//
//  Created by REVERSS on 12/12/2025.
//


//
//  Header.swift
//  jamly
//
//  Created by REVERSS on 07/12/2025.
//

import SwiftUI

struct Header: View {
    @EnvironmentObject private var userStore: UserStore
    
    @Binding var selectedSegment: FeedSegment
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                // Avatar + badge notifs
                ZStack(alignment: .topTrailing) {
                    if let user = userStore.user, let profilePicture = user.profilePicture {
                        AsyncImage(url: URL(string: profilePicture)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 36, height: 36)
                                .overlay {
                                    ProgressView()
                                }
                        }
                    } else {
                        // ✅ Pas d'user OU pas de photo
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            .frame(width: 36, height: 36)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                            }
                    }
                }
                
                Spacer()
                
                // Segmented "Mes amis / Discovery"
                HStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Button(action: { selectedSegment = .friends }) {
                            Text("Friends")
                                .fontWeight(.semibold)
                                .opacity(selectedSegment == .friends ? 1 : 0.6)
                                .foregroundColor(.primary)
                        }
                        if selectedSegment == .friends {
                            Capsule()
                                .fill(Color.white)
                                .frame(width: 40, height: 3)
                        } else {
                            Spacer().frame(height: 3)
                        }
                    }
                    VStack(spacing: 4) {
                        Button(action: { selectedSegment = .discovery }) {
                            Text("Discovery")
                                .fontWeight(.semibold)
                                .opacity(selectedSegment == .discovery ? 1 : 0.6)
                                .foregroundColor(.primary)
                        }
                        if selectedSegment == .discovery {
                            Capsule()
                                .fill(Color.white)
                                .frame(width: 50, height: 3)
                        } else {
                            Spacer().frame(height: 3)
                        }
                    }
                }
                
                Spacer()

                NavigationLink(destination: SearchView().navigationBarBackButtonHidden(true)) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 22, weight:.semibold))
                        .tint(.white)
                }
            }
        }
        .padding(.horizontal, 25)
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.7), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
