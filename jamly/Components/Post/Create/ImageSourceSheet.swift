//
//  ImageSourceSheet.swift
//  jamly
//
//  Created by REVERSS on 29/12/2025.
//

import SwiftUI


struct ImageSourceSheet: View {
    var onCameraSelected: () -> Void
    var onGallerySelected: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 8)
            
            Text("Add a photo")
                .font(.custom("Poppins-SemiBold", size: 18))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                Button {
                    onCameraSelected()
                } label: {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Take a photo")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                }
                
                Button {
                    onGallerySelected()
                } label: {
                    HStack {
                        Image(systemName: "photo.fill")
                        Text("Choose an image from the gallery")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .presentationDetents([.height(220)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.ultraThinMaterial)
    }
}
