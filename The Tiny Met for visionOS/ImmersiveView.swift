//
//  ImmersiveView.swift
//  The Tiny Met for visionOS
//
//  Created by Dakota Kim on 8/18/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveGalleryView: View {
    @Environment(AppModel.self) private var appModel
    
    var body: some View {
        RealityView { content in
            // Create an immersive museum environment
            await setupImmersiveMuseum(content: content)
        } update: { content in
            // Update content based on app state
        }
        .gesture(
            TapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    // Handle tapping on artworks in immersive space
                    let entity = value.entity
                    if entity.name.hasPrefix("artwork_"),
                       let objectIDString = entity.name.components(separatedBy: "_").last,
                       let objectID = Int(objectIDString) {
                        print("Tapped artwork \(objectID)")
                    }
                }
        )
    }
    
    @MainActor
    private func setupImmersiveMuseum(content: RealityViewContent) async {
        // Create a virtual museum gallery space
        let galleryFloor = ModelEntity(
            mesh: MeshResource.generatePlane(width: 4, depth: 4),
            materials: [SimpleMaterial(color: .init(white: 0.9, alpha: 1.0), isMetallic: false)]
        )
        galleryFloor.transform.translation.y = -1.0
        content.add(galleryFloor)
        
        // Add walls with artwork
        let wallMaterial = SimpleMaterial(color: .init(white: 0.95, alpha: 1.0), isMetallic: false)
        
        let backWall = ModelEntity(
            mesh: MeshResource.generatePlane(width: 4, height: 3),
            materials: [wallMaterial]
        )
        backWall.transform.translation = [0, 0.5, -2]
        content.add(backWall)
        
        // Add ambient lighting (simplified for visionOS compatibility)
        let lightEntity = Entity()
        lightEntity.components.set(DirectionalLightComponent(
            color: .white,
            intensity: 800
        ))
        lightEntity.transform.rotation = simd_quatf(angle: -Float.pi/3, axis: [1, 0, 0])
        content.add(lightEntity)
    }
}

// Keep old name for compatibility 
typealias ImmersiveView = ImmersiveGalleryView

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
