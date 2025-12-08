//
//  FollowersView.swift
//  jamly
//
//  Created by REVERSS on 08/12/2025.
//

import SwiftUI

struct FollowingView: View {
    let following = ["Alice", "Bob", "Charlie"]
    
    var body: some View {
        List(following, id: \.self) { chat in
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
                        Text(chat)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                Spacer()
                
                Button {
                    
                } label: {
                    Text("Following")
                }
                .buttonStyle(.glass)
            }
            .frame(height: 40)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .listStyle(.plain)
        
        .navigationTitle("Following")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    FollowingView()
}
