//
//  TikTokTabBar.swift
//  jamly
//
//  Created by REVERSS on 06/12/2025.
//

import SwiftUI

struct TabBar: View {
    @Binding var selectedTab: TabItem
    
    var body: some View {
        HStack(spacing: 24) {
            tabButton(
                tab: .home,
                title: "Home",
                systemImage: "house"
            )
            
            tabButton(
                tab: .discover,
                title: "Discover",
                systemImage: "safari"
            )
            
            // Gros bouton central
            createButton()
            
            tabButton(
                tab: .chats,
                title: "Chats",
                systemImage: "ellipsis.message"
            )
            
            tabButton(
                tab: .profile,
                title: "Profile",
                systemImage: "person"
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(
            Color.black
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    // Boutons “classiques”
    @ViewBuilder
    private func tabButton(tab: TabItem, title: String, systemImage: String) -> some View {
        let isSelected = selectedTab == tab
        
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 2) {
                Image(systemName: systemImage)
                    .environment(\.symbolVariants, isSelected ? .fill : .none)
                    .font(.system(size: 20))
                    .symbolRenderingMode(.monochrome)
                    .foregroundColor(isSelected ? .white : .gray)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white : .gray)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
    
    // Bouton central “+”
    @ViewBuilder
    private func createButton() -> some View {
        Button {
            selectedTab = .create
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [.blue, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 45, height: 32)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .frame(width: 40, height: 28)
                
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TabBar(selectedTab: .constant(.home))
}
