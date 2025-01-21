//
//  ImageInspectView.swift
//  The Tiny Met
//
//  Created by Dakota Kim on 10/28/24.
//

import SwiftUI

struct ImageInspectView: View {
    let imageURL: String
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    
    var body: some View {
            AsyncImage(url: URL(string: imageURL)) { image in
                image
                    .resizable()
                    .cornerRadius(10.0)
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(offset)
                    .onTapGesture(count: 2) {
                        print("Double tapped!")
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
            } placeholder: {
                ProgressView()
            }
        
    }
}
