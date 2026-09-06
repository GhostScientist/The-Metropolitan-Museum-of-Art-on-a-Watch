//
//  ImageInspectView.swift
//  The Tiny Met
//
//  Created by Dakota Kim on 10/28/24.
//

import SwiftUI

@MainActor
struct ImageInspectView: View {
    let imageURL: String
    var fallbackURL: String = ""
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    
    var body: some View {
        VStack {
            ArtworkImageView(imageURL: imageURL, fallbackURL: fallbackURL, maxPixelSize: 1_024)
                    .cornerRadius(10.0)
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(offset)
                    .onTapGesture(count: 2) {
                        withAnimation(.spring()) {
                            scale = 1.0
                            offset = .zero
                        }
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                offset = value.translation
                            }
                            .onEnded { _ in
                                withAnimation(.spring()) {
                                    offset = .zero
                                }
                            }
                        
                    )
            
            HStack {
                Button(action: {
                    withAnimation {
                        scale = max(scale - 0.5, 1.0)
                    }
                }) {
                    Image(systemName: "minus")
                }
                
                Button(action: {
                    withAnimation {
                        scale = min(scale + 0.5, 5.0)
                    }
                }) {
                    Image(systemName: "plus")
                }
            }
        }
    }
}
