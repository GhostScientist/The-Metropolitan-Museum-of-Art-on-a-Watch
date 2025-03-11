//
//  ImmersiveArtworkView.swift
//  The Met for VisionOS
//
//  Created by Dakota Kim on 1/20/25.
//

import SwiftUI
// Remove RealityKit since we're not using 3D models anymore
// import RealityKit

struct ImmersiveArtworkView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    
    let imageURL: String
    
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Angle = .zero
    @State private var offset: CGSize = .zero
    @State private var showControls = true
    @State private var frameStyle: FrameStyle = .modern
    @State private var backgroundStyle: BackgroundStyle = .museum
    @State private var isLoading = true
    
    enum FrameStyle: String, CaseIterable, Identifiable {
        case none = "No Frame"
        case simple = "Simple"
        case modern = "Modern"
        case ornate = "Ornate"
        case floating = "Floating"
        
        var id: String { self.rawValue }
    }
    
    enum BackgroundStyle: String, CaseIterable, Identifiable {
        case transparent = "Transparent"
        case museum = "Museum Wall"
        case gallery = "Gallery"
        case dark = "Dark"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        ZStack {
            // Background based on selected style
            Group {
                switch backgroundStyle {
                case .transparent:
                    Color.clear
                case .museum:
                    Color(red: 0.95, green: 0.95, blue: 0.95)
                case .gallery:
                    Color(red: 0.9, green: 0.9, blue: 0.9)
                case .dark:
                    Color(red: 0.1, green: 0.1, blue: 0.1)
                }
            }
            .ignoresSafeArea()
            
            // Main content
            VStack {
                // Artwork display
                ZStack {
                    // Background elements based on style
                    if backgroundStyle == .museum {
                        Rectangle()
                            .fill(Color(red: 0.92, green: 0.92, blue: 0.92))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .shadow(radius: 5)
                    } else if backgroundStyle == .gallery {
                        Image(systemName: "square.grid.3x3.fill")
                            .resizable(resizingMode: .tile)
                            .foregroundColor(Color.gray.opacity(0.1))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    
                    // Replace 3D Artwork display with 2D AsyncImage
                    AsyncImage(url: URL(string: imageURL)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .scaleEffect(1.5)
                                .onAppear {
                                    isLoading = true
                                }
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .onAppear {
                                    isLoading = false
                                }
                                .scaleEffect(scale)
                                .rotationEffect(rotation)
                                // Apply frame based on selected style
                                .overlay {
                                    if frameStyle != .none {
                                        GeometryReader { geo in 
                                            let width = geo.size.width
                                            let height = geo.size.height
                                            
                                            ZStack {
                                                // Frame styles
                                                switch frameStyle {
                                                case .simple:
                                                    Rectangle()
                                                        .stroke(Color(white: 0.2), lineWidth: 4)
                                                case .modern:
                                                    Rectangle()
                                                        .stroke(Color.white, lineWidth: 3)
                                                        .padding(3)
                                                        .background(
                                                            Rectangle()
                                                                .stroke(Color(white: 0.2), lineWidth: 2)
                                                        )
                                                case .ornate:
                                                    Rectangle()
                                                        .stroke(Color(red: 0.7, green: 0.5, blue: 0.2), lineWidth: 8)
                                                        .overlay(
                                                            Rectangle()
                                                                .stroke(Color(red: 0.8, green: 0.7, blue: 0.3), lineWidth: 3)
                                                                .padding(4)
                                                        )
                                                case .floating:
                                                    Rectangle()
                                                        .inset(by: -10)
                                                        .stroke(Color.white.opacity(0.7), lineWidth: 1)
                                                        .shadow(color: .white.opacity(0.3), radius: 10)
                                                default:
                                                    EmptyView()
                                                }
                                            }
                                            .frame(width: width, height: height)
                                        }
                                    }
                                }
                        case .failure:
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.yellow)
                                .onAppear {
                                    isLoading = false
                                }
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(minWidth: 300, minHeight: 300, maxHeight: 600)
                    .padding()
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = value
                            }
                            .onEnded { _ in
                                withAnimation {
                                    scale = max(0.5, min(scale, 3.0))
                                }
                            }
                    )
                    .gesture(
                        RotationGesture()
                            .onChanged { value in
                                rotation = value
                            }
                    )
                    .contentShape(Rectangle())
                }
                
                // Controls
                if showControls {
                    VStack(spacing: 20) {
                        // Frame style picker
                        HStack {
                            Text("Frame:")
                                .font(.headline)
                            
                            Picker("Frame Style", selection: $frameStyle) {
                                ForEach(FrameStyle.allCases) { style in
                                    Text(style.rawValue).tag(style)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 300)
                        }
                        
                        // Background style picker
                        HStack {
                            Text("Background:")
                                .font(.headline)
                            
                            Picker("Background Style", selection: $backgroundStyle) {
                                ForEach(BackgroundStyle.allCases) { style in
                                    Text(style.rawValue).tag(style)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 300)
                        }
                        
                        // Reset button
                        Button("Reset View") {
                            withAnimation {
                                scale = 1.0
                                rotation = .zero
                                offset = .zero
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .padding()
                }
            }
            
            // Toggle controls button
            VStack {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding()
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            showControls.toggle()
                        }
                    }) {
                        Image(systemName: showControls ? "chevron.down.circle.fill" : "chevron.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding()
                }
                Spacer()
            }
        }
    }
    
    // Remove the 3D addFrame method since it's no longer needed
}

#Preview {
    ImmersiveArtworkView(imageURL: "https://images.metmuseum.org/CRDImages/as/original/DP123239.jpg")
} 