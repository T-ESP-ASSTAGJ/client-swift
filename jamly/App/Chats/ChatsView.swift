//
//  ChatsView.swift
//  jamly
//
//  Created by REVERSS on 08/12/2025.
//

import SwiftUI

struct ChatsView: View {
    @State private var selectedChat: String?
    let chats = ["Alice", "Bob", "Charlie"]
    
    var body: some View {
        List(chats, id: \.self) { chat in
            Button {
                selectedChat = chat
            }label: {
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
                            
                            Text("Qu'est ce tu fou sur cette app ? 😂")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        HStack {
                            Text("10:38")
                                .font(.footnote)
                                .foregroundColor(.gray)
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                .frame(height: 60)
            }
            .buttonStyle(.borderless)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden, edges: .top)
            .listRowSeparator(chats.last == chat ? .hidden : .visible, edges: .bottom)
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .listStyle(.plain)
        .navigationTitle("Chats")
        .navigationDestination(item: $selectedChat) { chat in
            ChatDetailView(chatName: chat)
        }
    }
}

#Preview {
    ChatsView()
        .preferredColorScheme(.dark)
}
