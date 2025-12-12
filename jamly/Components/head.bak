//
//  Header.swift
//  jamly
//
//  Created by REVERSS on 07/12/2025.
//

import SwiftUI

struct Header: View {
    @State private var selectedSegment: FeedSegment = .discovery
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                // Avatar + badge notifs
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image("avatar1")
                                .resizable()
                                .scaledToFill()
                                .clipShape(Circle())
                        )
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
                
                // Loupe
                Button(action: {}) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 22, weight: .semibold))
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

#Preview {
    Header()
}
