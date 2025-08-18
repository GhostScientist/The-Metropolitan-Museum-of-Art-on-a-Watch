//
//  FullscreenImageView.swift
//  The Tiny Met for visionOS
//
//  Created by Dakota Kim on 8/18/25.
//

import SwiftUI

struct FullscreenImageView: View {
    let imageURL: String
    let title: String
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var isImageLoaded = false
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack {
                // Header
                HStack {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.6), in: Capsule())
                    
                    Spacer()
                    
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                // Zoomable image
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .onAppear {
                            withAnimation(.easeIn(duration: 0.3)) {
                                isImageLoaded = true
                            }
                        }
                        .gesture(
                            SimultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        withAnimation(.interactiveSpring()) {
                                            scale = max(0.5, min(4.0, value))
                                        }
                                    }
                                    .onEnded { _ in
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            if scale < 1.0 {
                                                scale = 1.0
                                                offset = .zero
                                            }
                                        }
                                    },
                                DragGesture()
                                    .onChanged { value in
                                        if scale > 1.0 {
                                            offset = value.translation
                                        }
                                    }
                                    .onEnded { _ in
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            if scale <= 1.0 {
                                                offset = .zero
                                            }
                                        }
                                    }
                            )
                        )
                        .onTapGesture(count: 2) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                if scale > 1.0 {
                                    scale = 1.0
                                    offset = .zero
                                } else {
                                    scale = 2.5
                                }
                            }
                        }
                } placeholder: {
                    VStack(spacing: 20) {
                        WaveLoadingView()
                        Text("Loading high resolution image...")
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                // Instructions
                if scale == 1.0 {
                    HStack(spacing: 20) {
                        Label("Pinch to zoom", systemImage: "hand.pinch")
                        Label("Double tap to zoom", systemImage: "hand.tap.fill")
                    }
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding()
                    .background(.black.opacity(0.4), in: Capsule())
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .opacity(isImageLoaded ? 1.0 : 0.0)
    }
}

extension View {
    func shimmer(duration: Double = 1.5) -> some View {
        self.modifier(ShimmerModifier(duration: duration))
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var offset: CGFloat = -300
    let duration: Double
    
    func body(content: Content) -> some View {
        content
            .overlay {
                RoundedRectangle(cornerRadius: 15)
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.2), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: offset)
                    .animation(
                        .linear(duration: duration)
                        .repeatForever(autoreverses: false),
                        value: offset
                    )
                    .onAppear {
                        offset = 300
                    }
            }
    }
}

#Preview {
    FullscreenImageView(
        imageURL: "https://images.metmuseum.org/CRDImages/ep/original/DT1567.jpg",
        title: "The Starry Night"
    )
}