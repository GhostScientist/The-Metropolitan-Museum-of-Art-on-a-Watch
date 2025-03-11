//
//  OnboardingView.swift
//  The Met for VisionOS
//
//  Created by Dakota Kim on 1/20/25.
//

import SwiftUI
import RealityKit

struct OnboardingView: View {
    var onComplete: () -> Void
    
    @State private var currentPage = 0
    @State private var showContinueButton = false
    @State private var rotationAngle: Double = 0
    @State private var floatAnimation: Bool = false
    @State private var scaleAnimation: CGFloat = 1.0
    
    private let pages = [
        OnboardingPage(
            title: "Welcome to The Met",
            description: "Experience the Metropolitan Museum of Art's priceless collection in a revolutionary spatial environment.",
            imageName: "building.columns.fill",
            color: Color(red: 0.9, green: 0.3, blue: 0.3),
            modelName: "museum"
        ),
        OnboardingPage(
            title: "Discover Masterpieces",
            description: "Browse through centuries of artistic genius across different departments and periods.",
            imageName: "photo.stack.fill",
            color: Color(red: 0.3, green: 0.6, blue: 0.9),
            modelName: "artworks"
        ),
        OnboardingPage(
            title: "Immersive Experience",
            description: "Step into the artwork and explore details that would be impossible to see in person.",
            imageName: "eye.fill",
            color: Color(red: 0.5, green: 0.3, blue: 0.8),
            modelName: "immersive"
        ),
        OnboardingPage(
            title: "Your Personal Gallery",
            description: "Create your own exhibition with favorite artworks displayed in a customizable virtual space.",
            imageName: "person.fill.viewfinder",
            color: Color(red: 0.1, green: 0.7, blue: 0.6),
            modelName: "gallery"
        )
    ]
    
    var body: some View {
        ZStack {
            // Background - subtle depth layers
            ZStack {
                // Deep background layer
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.8), Color.black]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Atmospheric particle effects
                ForEach(0..<30) { index in
                    Circle()
                        .fill(Color.white.opacity(Double.random(in: 0.02...0.1)))
                        .frame(width: CGFloat.random(in: 2...8), height: CGFloat.random(in: 2...8))
                        .position(x: CGFloat.random(in: 0...600), y: CGFloat.random(in: 0...800))
                        .blur(radius: CGFloat.random(in: 1...3))
                }
            }
            
            // Main content
            VStack(spacing: 40) {
                Spacer().frame(height: 60)
                
                // 3D visual elements
                ZStack {
                    // 3D model placeholder - would be replaced with actual Reality Composer Pro models
                    RealityView { content in
                        // Create a dynamic 3D model based on current page
                        let modelEntity = createModel(for: pages[currentPage].modelName)
                        
                        // Add to content
                        content.add(modelEntity)
                    } update: { content in
                        // Update model when page changes
                        guard let modelEntity = content.entities.first else { return }
                        
                        // Update model appearance based on current page
                        updateModel(modelEntity, for: pages[currentPage].modelName)
                    }
                    .frame(width: 300, height: 300)
                    .scaleEffect(scaleAnimation)
                    .rotation3DEffect(.degrees(rotationAngle), axis: (x: 0, y: 1, z: 0.2))
                    .offset(y: floatAnimation ? -10 : 10)
                }
                .frame(height: 320)
                .padding(.vertical, 20)
                .onAppear {
                    withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                        rotationAngle = 360
                    }
                    withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                        floatAnimation = true
                    }
                    withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                        scaleAnimation = 1.05
                    }
                }
                
                // Title and description with depth
                VStack(spacing: 25) {
                    Text(pages[currentPage].title)
                        .font(.system(size: 42, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                        .transition(.scale.combined(with: .opacity))
                        .drawingGroup()
                        .visualEffect { content, geometryProxy in
                            content
                                .offset(z: 20)
                        }
                    
                    Text(pages[currentPage].description)
                        .font(.system(size: 22, weight: .medium, design: .serif))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 500)
                        .padding(.horizontal)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                        .visualEffect { content, geometryProxy in
                            content
                                .offset(z: 10)
                        }
                }
                .padding()
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: currentPage)
                
                Spacer()
                
                // Page indicators with navigation buttons
                HStack {
                    if currentPage > 0 {
                        Button(action: {
                            withAnimation {
                                currentPage -= 1
                            }
                        }) {
                            Label("Previous", systemImage: "chevron.left")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity)
                    }
                    
                    Spacer()
                    
                    // Page indicators
                    HStack(spacing: 12) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? pages[index].color : Color.white.opacity(0.3))
                                .frame(width: 12, height: 12)
                                .scaleEffect(currentPage == index ? 1.2 : 1.0)
                                .shadow(color: currentPage == index ? pages[index].color.opacity(0.7) : .clear, radius: 5)
                                .animation(.spring(), value: currentPage)
                                .onTapGesture {
                                    withAnimation {
                                        currentPage = index
                                    }
                                }
                        }
                    }
                    
                    Spacer()
                    
                    // Next/Complete button
                    Button(action: {
                        if currentPage < pages.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            withAnimation {
                                onComplete()
                            }
                        }
                    }) {
                        Label(currentPage < pages.count - 1 ? "Next" : "Begin Experience", 
                              systemImage: currentPage < pages.count - 1 ? "chevron.right" : "sparkles")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding(.horizontal, currentPage < pages.count - 1 ? 20 : 25)
                            .padding(.vertical, 12)
                            .background(currentPage < pages.count - 1 ? Color.white : pages[currentPage].color)
                            .clipShape(Capsule())
                            .shadow(color: currentPage < pages.count - 1 ? .white.opacity(0.3) : pages[currentPage].color.opacity(0.5), radius: 8)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.defaultAction)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
                .frame(maxWidth: 600)
            }
            .padding()
        }
        .onAppear {
            // Show continue button after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    showContinueButton = true
                }
            }
        }
    }
    
    // Helper functions to create and update 3D models
    private func createModel(for modelName: String) -> ModelEntity {
        // In a real app, we would load actual models from RealityKit Content
        // For now we're creating simple placeholder models
        switch modelName {
        case "museum":
            // Museum building model
            let meshResource = MeshResource.generateBox(size: 0.15, cornerRadius: 0.02)
            let material = SimpleMaterial(color: .white, roughness: 0.2, isMetallic: true)
            let entity = ModelEntity(mesh: meshResource, materials: [material])
            
            // Add columns
            for i in 0..<4 {
                let columnMesh = MeshResource.generateBox(size: [0.02, 0.1, 0.02])
                let columnMaterial = SimpleMaterial(color: .white, roughness: 0.1, isMetallic: false)
                let column = ModelEntity(mesh: columnMesh, materials: [columnMaterial])
                
                // Position columns in front
                let xPos = Float(-0.06 + Float(i) * 0.04)
                column.position = SIMD3(xPos, -0.05, 0.076)
                entity.addChild(column)
            }
            
            // Add roof
            let roofMesh = MeshResource.generateBox(size: [0.17, 0.03, 0.17], cornerRadius: 0.01)
            let roofMaterial = SimpleMaterial(color: .white.withAlphaComponent(0.9), roughness: 0.2, isMetallic: true)
            let roof = ModelEntity(mesh: roofMesh, materials: [roofMaterial])
            roof.position = SIMD3(0, 0.08, 0)
            entity.addChild(roof)
            
            return entity
            
        case "artworks":
            // Stacked artwork frames
            let rootEntity = ModelEntity()
            
            // Create multiple frames in a artistic arrangement
            for i in 0..<5 {
                let frameWidth = Float.random(in: 0.08...0.12)
                let frameHeight = Float.random(in: 0.08...0.12)
                let frameMesh = MeshResource.generatePlane(width: frameWidth, height: frameHeight)
                let frameColor = [
                    Color(red: 0.9, green: 0.7, blue: 0.3),
                    Color(red: 0.3, green: 0.5, blue: 0.9),
                    Color(red: 0.7, green: 0.3, blue: 0.5),
                    Color(red: 0.4, green: 0.7, blue: 0.4),
                    Color(red: 0.8, green: 0.4, blue: 0.2)
                ][i % 5]
                
                // Convert SwiftUI Color to UIColor for SimpleMaterial
                let uiFrameColor = UIColor(frameColor)
                let frameMaterial = SimpleMaterial(color: uiFrameColor, roughness: 0.3, isMetallic: false)
                let frame = ModelEntity(mesh: frameMesh, materials: [frameMaterial])
                
                // Position frames in a scattered artistic arrangement
                let xOffset = Float.random(in: -0.1...0.1)
                let yOffset = Float.random(in: -0.1...0.1)
                let zOffset = Float(i) * 0.02
                frame.position = SIMD3(xOffset, yOffset, zOffset)
                
                // Random rotation
                frame.orientation = simd_quatf(angle: .random(in: -0.2...0.2), axis: [0, 0, 1])
                
                rootEntity.addChild(frame)
            }
            
            return rootEntity
            
        case "immersive":
            // Eye-like structure with rays
            let rootEntity = ModelEntity()
            
            // Create central eye
            let eyeMesh = MeshResource.generateSphere(radius: 0.05)
            let eyeMaterial = SimpleMaterial(color: .white, roughness: 0.1, isMetallic: true)
            let eye = ModelEntity(mesh: eyeMesh, materials: [eyeMaterial])
            rootEntity.addChild(eye)
            
            // Add iris
            let irisMesh = MeshResource.generateSphere(radius: 0.025)
            // Convert SwiftUI Color to UIColor for SimpleMaterial
            let uiIrisColor = UIColor(Color(red: 0.1, green: 0.4, blue: 0.8))
            let irisMaterial = SimpleMaterial(color: uiIrisColor, roughness: 0.1, isMetallic: true)
            let iris = ModelEntity(mesh: irisMesh, materials: [irisMaterial])
            iris.position = SIMD3(0, 0, 0.03)
            eye.addChild(iris)
            
            // Add rays emanating from the eye
            for i in 0..<12 {
                let rayMesh = MeshResource.generateBox(size: [0.01, 0.01, 0.15])
                let rayMaterial = SimpleMaterial(color: .white.withAlphaComponent(0.7), roughness: 0.3, isMetallic: false)
                let ray = ModelEntity(mesh: rayMesh, materials: [rayMaterial])
                
                // Position rays in a circle
                let angle = Float(i) * (2 * Float.pi / 12)
                let radius: Float = 0.12
                ray.position = SIMD3(radius * sin(angle), radius * cos(angle), 0)
                
                // Orient ray to point outward
                ray.look(at: SIMD3(0, 0, 0), from: ray.position, upVector: SIMD3(0, 0, 1), relativeTo: nil)
                
                rootEntity.addChild(ray)
            }
            
            return rootEntity
            
        case "gallery":
            // Personal gallery model
            let rootEntity = ModelEntity()
            
            // Floor
            let floorMesh = MeshResource.generatePlane(width: 0.3, height: 0.3)
            // Convert SwiftUI Color to UIColor for SimpleMaterial
            let uiFloorColor = UIColor(Color(white: 0.9))
            let floorMaterial = SimpleMaterial(color: uiFloorColor, roughness: 0.2, isMetallic: false)
            let floor = ModelEntity(mesh: floorMesh, materials: [floorMaterial])
            floor.position = SIMD3(0, -0.1, 0)
            rootEntity.addChild(floor)
            
            // Walls
            let wallMesh = MeshResource.generatePlane(width: 0.3, height: 0.15)
            // Convert SwiftUI Color to UIColor for SimpleMaterial
            let uiWallColor = UIColor(Color(white: 0.95))
            let wallMaterial = SimpleMaterial(color: uiWallColor, roughness: 0.1, isMetallic: false)
            
            // Back wall
            let backWall = ModelEntity(mesh: wallMesh, materials: [wallMaterial])
            backWall.position = SIMD3(0, -0.025, -0.15)
            backWall.orientation = simd_quatf(angle: Float.pi/2, axis: [1, 0, 0])
            rootEntity.addChild(backWall)
            
            // Left wall
            let leftWall = ModelEntity(mesh: wallMesh, materials: [wallMaterial])
            leftWall.position = SIMD3(-0.15, -0.025, 0)
            leftWall.orientation = simd_quatf(angle: Float.pi/2, axis: [0, 0, 1])
            rootEntity.addChild(leftWall)
            
            // Right wall
            let rightWall = ModelEntity(mesh: wallMesh, materials: [wallMaterial])
            rightWall.position = SIMD3(0.15, -0.025, 0)
            rightWall.orientation = simd_quatf(angle: -Float.pi/2, axis: [0, 0, 1])
            rootEntity.addChild(rightWall)
            
            // Add tiny artwork frames
            for i in 0..<3 {
                let frameWidth: Float = 0.06
                let frameHeight: Float = 0.04
                let frameMesh = MeshResource.generatePlane(width: frameWidth, height: frameHeight)
                // Convert SwiftUI Color to UIColor for SimpleMaterial
                let uiFrameColor = UIColor(Color(white: 0.2))
                let frameMaterial = SimpleMaterial(color: uiFrameColor, roughness: 0.1, isMetallic: false)
                let frame = ModelEntity(mesh: frameMesh, materials: [frameMaterial])
                
                // Position on back wall
                let xPos = Float(-0.08 + Float(i) * 0.08)
                frame.position = SIMD3(xPos, 0, -0.145)
                frame.orientation = simd_quatf(angle: Float.pi/2, axis: [1, 0, 0])
                
                rootEntity.addChild(frame)
            }
            
            // Add a tiny person silhouette
            let personMesh = MeshResource.generateBox(size: [0.015, 0.04, 0.01])
            // Convert SwiftUI Color to UIColor for SimpleMaterial
            let uiPersonColor = UIColor(Color(white: 0.2))
            let personMaterial = SimpleMaterial(color: uiPersonColor, roughness: 0.1, isMetallic: false)
            let person = ModelEntity(mesh: personMesh, materials: [personMaterial])
            person.position = SIMD3(0, -0.08, 0)
            rootEntity.addChild(person)
            
            return rootEntity
            
        default:
            // Default simple sphere
            let mesh = MeshResource.generateSphere(radius: 0.1)
            let material = SimpleMaterial(color: .white, roughness: 0.5, isMetallic: true)
            return ModelEntity(mesh: mesh, materials: [material])
        }
    }
    
    private func updateModel(_ entity: Entity, for modelName: String) {
        // In a real implementation, this would update the model's appearance
        // Here we're just doing a simple rotation or adjustment
        if let modelEntity = entity as? ModelEntity {
            // Apply subtle animation or changes
            modelEntity.transform.rotation = simd_quatf(angle: .pi * Float(rotationAngle) / 180, axis: [0, 1, 0])
        }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
    let color: Color
    let modelName: String
}

#Preview {
    OnboardingView(onComplete: {})
} 