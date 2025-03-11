//
//  ImmersiveArtworkView.swift
//  The Met for VisionOS
//
//  Created by Dakota Kim on 1/20/25.
//

import SwiftUI
import RealityKit

struct ImmersiveArtworkView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    
    let imageURL: String
    
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Angle = .zero
    @State private var offset: SIMD3<Float> = .zero
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
    
    private func addFrame(to entity: ModelEntity, width: Float, height: Float) async {
        // Add frame based on selected style
        switch frameStyle {
        case .none:
            // No frame
            break
            
        case .simple:
            // Simple frame
            let frameWidth: Float = 0.05
            let frameDepth: Float = 0.01
            
            // Create frame parts
            let topFrame = ModelEntity(mesh: .generateBox(width: width + frameWidth * 2, height: frameWidth, depth: frameDepth))
            let bottomFrame = ModelEntity(mesh: .generateBox(width: width + frameWidth * 2, height: frameWidth, depth: frameDepth))
            let leftFrame = ModelEntity(mesh: .generateBox(width: frameWidth, height: height, depth: frameDepth))
            let rightFrame = ModelEntity(mesh: .generateBox(width: frameWidth, height: height, depth: frameDepth))
            
            // Position frame parts
            topFrame.position = SIMD3<Float>(0, height / 2 + frameWidth / 2, -frameDepth / 2)
            bottomFrame.position = SIMD3<Float>(0, -height / 2 - frameWidth / 2, -frameDepth / 2)
            leftFrame.position = SIMD3<Float>(-width / 2 - frameWidth / 2, 0, -frameDepth / 2)
            rightFrame.position = SIMD3<Float>(width / 2 + frameWidth / 2, 0, -frameDepth / 2)
            
            // Create frame material
            let frameMaterial = SimpleMaterial(color: .black, roughness: 0.5, isMetallic: false)
            topFrame.model?.materials = [frameMaterial]
            bottomFrame.model?.materials = [frameMaterial]
            leftFrame.model?.materials = [frameMaterial]
            rightFrame.model?.materials = [frameMaterial]
            
            // Add frame parts to entity
            entity.addChild(topFrame)
            entity.addChild(bottomFrame)
            entity.addChild(leftFrame)
            entity.addChild(rightFrame)
            
        case .modern:
            // Modern frame with shadow effect
            let frameWidth: Float = 0.03
            let frameDepth: Float = 0.02
            let shadowOffset: Float = 0.005
            
            // Create main frame
            let frame = ModelEntity(mesh: .generateBox(width: width + frameWidth * 2, height: height + frameWidth * 2, depth: frameDepth))
            frame.position = SIMD3<Float>(0, 0, -frameDepth / 2 - 0.001)
            
            // Create shadow
            let shadow = ModelEntity(mesh: .generateBox(width: width + frameWidth * 2 + shadowOffset * 2, height: height + frameWidth * 2 + shadowOffset * 2, depth: 0.001))
            shadow.position = SIMD3<Float>(shadowOffset, -shadowOffset, -frameDepth - 0.002)
            
            // Create materials
            let frameMaterial = SimpleMaterial(color: .white, roughness: 0.1, isMetallic: false)
            let shadowMaterial = SimpleMaterial(color: .black.withAlphaComponent(0.3), roughness: 1.0, isMetallic: false)
            
            frame.model?.materials = [frameMaterial]
            shadow.model?.materials = [shadowMaterial]
            
            // Add to entity
            entity.addChild(shadow)
            entity.addChild(frame)
            
        case .ornate:
            // Ornate gold frame
            let frameWidth: Float = 0.08
            let frameDepth: Float = 0.03
            
            // Create frame parts with rounded corners
            let topFrame = ModelEntity(mesh: .generateBox(width: width + frameWidth * 2, height: frameWidth, depth: frameDepth, cornerRadius: frameWidth / 4))
            let bottomFrame = ModelEntity(mesh: .generateBox(width: width + frameWidth * 2, height: frameWidth, depth: frameDepth, cornerRadius: frameWidth / 4))
            let leftFrame = ModelEntity(mesh: .generateBox(width: frameWidth, height: height, depth: frameDepth, cornerRadius: frameWidth / 4))
            let rightFrame = ModelEntity(mesh: .generateBox(width: frameWidth, height: height, depth: frameDepth, cornerRadius: frameWidth / 4))
            
            // Position frame parts
            topFrame.position = SIMD3<Float>(0, height / 2 + frameWidth / 2, -frameDepth / 2)
            bottomFrame.position = SIMD3<Float>(0, -height / 2 - frameWidth / 2, -frameDepth / 2)
            leftFrame.position = SIMD3<Float>(-width / 2 - frameWidth / 2, 0, -frameDepth / 2)
            rightFrame.position = SIMD3<Float>(width / 2 + frameWidth / 2, 0, -frameDepth / 2)
            
            // Create ornate gold material
            let goldMaterial = SimpleMaterial(color: .init(red: 0.85, green: 0.7, blue: 0.25, alpha: 1.0), roughness: 0.3, isMetallic: true)
            topFrame.model?.materials = [goldMaterial]
            bottomFrame.model?.materials = [goldMaterial]
            leftFrame.model?.materials = [goldMaterial]
            rightFrame.model?.materials = [goldMaterial]
            
            // Add frame parts to entity
            entity.addChild(topFrame)
            entity.addChild(bottomFrame)
            entity.addChild(leftFrame)
            entity.addChild(rightFrame)
            
        case .floating:
            // Floating effect with shadow
            let shadowDepth: Float = 0.01
            let shadowOffset: Float = 0.02
            
            // Create shadow
            let shadow = ModelEntity(mesh: .generatePlane(width: width + shadowOffset * 2, height: height + shadowOffset * 2))
            shadow.position = SIMD3<Float>(0, 0, -shadowDepth)
            
            // Create shadow material
            let shadowMaterial = SimpleMaterial(color: .black.withAlphaComponent(0.2), roughness: 1.0, isMetallic: false)
            shadow.model?.materials = [shadowMaterial]
            
            // Add shadow to entity
            entity.addChild(shadow)
        }
    }
}

#Preview {
    ImmersiveArtworkView(imageURL: "https://images.metmuseum.org/CRDImages/as/original/DP123239.jpg")
} 