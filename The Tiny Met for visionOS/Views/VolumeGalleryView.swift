//
//  VolumeGalleryView.swift
//  The Tiny Met for visionOS
//
//  Created by Dakota Kim on 8/18/25.
//

import SwiftUI
import RealityKit

struct VolumeGalleryView: View {
    let department: Department
    
    @State private var artworks: [ObjectDetails] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    private let metMuseumClient = MetMuseumClient()
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        ZStack {
            if isLoading {
                VStack(spacing: 15) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Curating Gallery...")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            } else if let errorMessage = errorMessage {
                VStack(spacing: 15) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundStyle(.orange)
                    Text(errorMessage)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                }
            } else {
                RealityView { content in
                    setupVolumetricGallery(content: content)
                } update: { content in
                    updateGalleryContent(content: content)
                }
            }
        }
        .navigationTitle("\(department.displayName) Gallery")
        .task {
            await loadFeaturedArtworks()
        }
    }
    
    private func loadFeaturedArtworks() async {
        do {
            let objectsResult = try await metMuseumClient.fetchObjects(departmentId: department.departmentId)
            let featuredIDs = Array(objectsResult.objectIDs.prefix(15)) // Load 15 featured pieces
            
            let loadedArtworks = try await withThrowingTaskGroup(of: ObjectDetails?.self) { group in
                for id in featuredIDs {
                    group.addTask {
                        do {
                            return try await metMuseumClient.fetchObjectDetails(objectID: id)
                        } catch {
                            return nil
                        }
                    }
                }
                
                var results: [ObjectDetails] = []
                for try await artwork in group {
                    if let artwork = artwork, !artwork.primaryImage.isEmpty {
                        results.append(artwork)
                    }
                }
                return results
            }
            
            await MainActor.run {
                self.artworks = loadedArtworks
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load gallery"
                self.isLoading = false
            }
        }
    }
    
    private func setupVolumetricGallery(content: RealityViewContent) {
        // Create gallery layout in 3D space
        let galleryRadius: Float = 0.4
        let artworksPerRow = 5
        
        for (index, artwork) in artworks.enumerated() {
            guard index < 15 else { break } // Limit to 15 artworks for performance
            
            let level = index / artworksPerRow
            let positionInLevel = index % artworksPerRow
            
            // Calculate position in 3D space
            let angle = Float(positionInLevel) * (2.0 * Float.pi / Float(artworksPerRow))
            let x = cos(angle) * galleryRadius
            let z = sin(angle) * galleryRadius
            let y = Float(level - 1) * 0.25 // Vertical spacing
            
            // Create artwork entity
            let artworkEntity = createArtworkEntity(for: artwork, at: [x, y, z])
            content.add(artworkEntity)
        }
        
        // Add ambient lighting
        let lightEntity = Entity()
        lightEntity.components.set(DirectionalLightComponent(
            color: .white,
            intensity: 1000
        ))
        lightEntity.transform.rotation = simd_quatf(angle: -Float.pi/4, axis: [1, 0, 0])
        content.add(lightEntity)
    }
    
    private func createArtworkEntity(for artwork: ObjectDetails, at position: SIMD3<Float>) -> Entity {
        let entity = Entity()
        entity.transform.translation = position
        
        // Create a frame for the artwork
        let frameWidth: Float = 0.12
        let frameHeight: Float = 0.16
        let frameDepth: Float = 0.02
        
        let frameMesh = MeshResource.generateBox(
            width: frameWidth,
            height: frameHeight,
            depth: frameDepth
        )
        
        // Create frame material
        var frameMaterial = UnlitMaterial(color: .init(white: 0.9, alpha: 1.0))
        frameMaterial.blending = .transparent(opacity: 0.95)
        
        let frameEntity = ModelEntity(mesh: frameMesh, materials: [frameMaterial])
        entity.addChild(frameEntity)
        
        // Add artwork plane (will be updated with image)
        let artworkMesh = MeshResource.generatePlane(
            width: frameWidth * 0.8,
            height: frameHeight * 0.8
        )
        
        let artworkEntity = ModelEntity(mesh: artworkMesh, materials: [SimpleMaterial(color: .gray, isMetallic: false)])
        artworkEntity.transform.translation.z = frameDepth * 0.6
        frameEntity.addChild(artworkEntity)
        
        // Add tap gesture for opening detail view
        entity.components.set(InputTargetComponent())
        entity.components.set(CollisionComponent(shapes: [.generateBox(width: frameWidth, height: frameHeight, depth: frameDepth)]))
        
        // Store artwork ID for interaction
        entity.name = "artwork_\(artwork.objectID)"
        
        // Face the user
        let lookAtTransform = Transform(scale: SIMD3<Float>(1, 1, 1), 
                                      rotation: simd_quatf(angle: 0, axis: [0, 1, 0]), 
                                      translation: position)
        entity.transform = lookAtTransform
        
        return entity
    }
    
    private func updateGalleryContent(content: RealityViewContent) {
        // Update artwork textures (would implement image loading here)
        // For now, keep default materials
    }
}

#Preview {
    VolumeGalleryView(department: Department(departmentId: 11, displayName: "European Paintings"))
}