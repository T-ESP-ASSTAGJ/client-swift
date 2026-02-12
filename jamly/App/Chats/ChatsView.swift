//
//  ChatsView.swift
//  jamly
//
//  Created by REVERSS on 08/12/2025.
//

import SwiftUI

struct ChatPreview: Identifiable, Equatable, Hashable {
    let id = UUID()
    let avatar: String
    let username: String
    let message: String
    let timestamp: String
}

let mockChats: [ChatPreview] = [
    ChatPreview(avatar: "avatar1", username: "Alice", message: "Hi, how are you?", timestamp: "16:13"),
    ChatPreview(avatar: "avatar2", username: "Kylian", message: "I'm doing well, thanks!", timestamp: "10:23"),
    ChatPreview(avatar: "avatar3", username: "Julia", message: "This app is so cool, the developers are so beautiful mainly Gaël", timestamp: "12:44")
]

struct ChatsView: View {
    @State private var selectedChat: ChatPreview?
    
    var body: some View {
        List(mockChats) { chat in
            Button {
                selectedChat = chat
            } label: {
                HStack(spacing: 8) {
                    HStack(spacing: 8) {
                        HStack(spacing: 15) {
                            Image(chat.avatar)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 44, height: 44)
                                .clipShape(Circle())
                            
                            // Infos
                            VStack(alignment: .leading) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(chat.username)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    HStack {
                                        Text(chat.timestamp)
                                            .font(.footnote)
                                            .foregroundColor(.gray)
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Text(chat.message)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineLimit(2)
                                    .truncationMode(.tail)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                    }
                    .frame(height: 60)
                }
                .frame(height: 60)
            }
            .buttonStyle(.borderless)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden, edges: .top)
            .listRowSeparator(chat.id == mockChats.last?.id ? .hidden : .visible, edges: .bottom)
        }
        .scrollContentBackground(.hidden)
        .listStyle(.plain)
        .navigationTitle("Chats")
        .navigationDestination(item: $selectedChat) { chat in
            ChatDetailView(chatName: chat.username)
        }
    }
}
