//
//  ChatDetailView.swift
//  jamly
//
//  Created by REVERSS on 31/12/2025.
//

import SwiftUI

struct ChatDetailView: View {
    let chatName: String
    
    var body: some View {
        VStack {
            Text("Chat with \(chatName)")
                .foregroundColor(.white)
        }
        .navigationTitle(chatName)
    }
}
