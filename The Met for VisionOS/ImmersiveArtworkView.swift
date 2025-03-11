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
                    
                    // 3D Artwork display
                    RealityView { content in
                        // Create a plane for the image
                        let planeMesh = MeshResource.generatePlane(width: 1, height: 1)
                        let planeEntity = ModelEntity(mesh: planeMesh)
                        
                        // Add the entity to the content first
                        content.add(planeEntity)
                        
                        // Create a material with the image
                        Task {
                            do {
                                let imageURL = URL(string: imageURL)!
                                let imageData = try await URLSession.shared.data(from: imageURL).0
                                if let uiImage = UIImage(data: imageData) {
                                    // Use TextureResource.load(named:) instead of await
                                    let texture = try TextureResource.load(contentsOf: imageURL)
                                    
                                    // Calculate aspect ratio
                                    let aspectRatio = uiImage.size.width / uiImage.size.height
                                    
                                    // Resize the plane to match the image aspect ratio
                                    let width: Float = aspectRatio >= 1.0 ? 1.0 : Float(aspectRatio)
                                    let height: Float = aspectRatio >= 1.0 ? 1.0 / Float(aspectRatio) : 1.0
                                    
                                    planeEntity.model?.mesh = MeshResource.generatePlane(width: width, height: height)
                                    
                                    // Create material with the image
                                    var material = UnlitMaterial()
                                    material.color = .init(texture: .init(texture))
                                    planeEntity.model?.materials = [material]
                                    
                                    // Add frame based on selected style
                                    await addFrame(to: planeEntity, width: width, height: height)
                                    
                                    await MainActor.run {
                                        isLoading = false
                                    }
                                }
                            } catch {
                                print("Error loading image: \(error)")
                                await MainActor.run {
                                    isLoading = false
                                }
                            }
                        }
                    } update: { content in
                        // Update the content when properties change
                        if let planeEntity = content.entities.first {
                            planeEntity.transform.scale = SIMD3<Float>(repeating: Float(scale))
                            planeEntity.transform.rotation = simd_quatf(angle: Float(rotation.radians), axis: SIMD3<Float>(0, 1, 0))
                            planeEntity.transform.translation = offset
                        }
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                // Convert drag to 3D offset
                                let dragX = Float(value.translation.width) / 500.0
                                let dragY = Float(-value.translation.height) / 500.0
                                offset = SIMD3<Float>(dragX, dragY, 0)
                            }
                    )
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
                    
                    // Loading indicator
                    if isLoading {
                        ProgressView()
                            .scaleEffect(2.0)
                    }
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