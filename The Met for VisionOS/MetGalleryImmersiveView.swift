//
//  MetGalleryImmersiveView.swift
//  The Met for VisionOS
//
//  Created by Dakota Kim on 1/20/25.
//

import SwiftUI
import RealityKit
import TheMetUtilities

struct MetGalleryImmersiveView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openWindow) private var openWindow
    
    @State private var featuredArtworks: [ObjectDetails] = []
    @State private var selectedArtwork: ObjectDetails?
    @State private var isLoading = true
    @State private var showOptions = false
    @State private var galleryStyle: GalleryStyle = .modern
    @State private var lightingStyle: LightingStyle = .natural
    
    private let metMuseumClient = MetMuseumClient()
    
    // Define a custom identity quaternion since the built-in one is internal
    private let identityQuaternion = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1)
    
    enum GalleryStyle: String, CaseIterable, Identifiable {
        case modern = "Modern"
        case classical = "Classical"
        case minimalist = "Minimalist"
        
        var id: String { self.rawValue }
    }
    
    enum LightingStyle: String, CaseIterable, Identifiable {
        case natural = "Natural"
        case warm = "Warm"
        case dramatic = "Dramatic"
        case cool = "Cool"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        ZStack {
            // Full immersive gallery view
            RealityView { content in
                // Create the gallery environment
                let galleryRoot = Entity()
                
                // Add gallery floor
                let floorSize: Float = 20.0
                let floorMesh = MeshResource.generatePlane(width: floorSize, height: floorSize)
                let floorMaterial = createFloorMaterial()
                let floor = ModelEntity(mesh: floorMesh, materials: [floorMaterial])
                floor.transform.translation = SIMD3<Float>(0, -1.5, 0)
                floor.transform.rotation = simd_quatf(angle: .pi/2, axis: SIMD3<Float>(1, 0, 0))
                floor.generateCollisionShapes(recursive: true)
                floor.components.set(PhysicsBodyComponent(massProperties: .default, mode: .static))
                galleryRoot.addChild(floor)
                
                // Add gallery walls
                let wallHeight: Float = 4.0
                let wallLength: Float = 15.0
                
                // Create walls
                let backWall = createWall(width: wallLength, height: wallHeight, depth: 0.1)
                backWall.transform.translation = SIMD3<Float>(0, wallHeight/2 - 1.5, -wallLength/2)
                galleryRoot.addChild(backWall)
                
                let leftWall = createWall(width: wallLength, height: wallHeight, depth: 0.1)
                leftWall.transform.translation = SIMD3<Float>(-wallLength/2, wallHeight/2 - 1.5, 0)
                leftWall.transform.rotation = simd_quatf(angle: .pi/2, axis: SIMD3<Float>(0, 1, 0))
                galleryRoot.addChild(leftWall)
                
                let rightWall = createWall(width: wallLength, height: wallHeight, depth: 0.1)
                rightWall.transform.translation = SIMD3<Float>(wallLength/2, wallHeight/2 - 1.5, 0)
                rightWall.transform.rotation = simd_quatf(angle: -.pi/2, axis: SIMD3<Float>(0, 1, 0))
                galleryRoot.addChild(rightWall)
                
                // Add museumlike touches based on style
                addGalleryElements(to: galleryRoot)
                
                // Add lighting
                addLighting(to: galleryRoot)
                
                // Add the gallery root to content
                content.add(galleryRoot)
                
                // Create a local copy of content to avoid capturing inout parameter
                let contentCopy = content
                
                // Load featured artworks
                Task {
                    await loadFeaturedArtworks(galleryRoot: galleryRoot, content: contentCopy)
                    
                    // Update loading state
                    await MainActor.run {
                        isLoading = false
                    }
                }
            } update: { content in
                // Update the gallery based on style changes
                if let root = content.entities.first {
                    // Update floor material
                    if let floor = root.findEntity(named: "floor") {
                        if var modelComponent = floor.components[ModelComponent.self] {
                            modelComponent.materials = [createFloorMaterial()]
                            floor.components.set(modelComponent)
                        }
                    }
                    
                    // Update wall material for all walls
                    for wallName in ["backWall", "leftWall", "rightWall"] {
                        if let wall = root.findEntity(named: wallName) {
                            if var modelComponent = wall.components[ModelComponent.self] {
                                modelComponent.materials = [createWallMaterial()]
                                wall.components.set(modelComponent)
                            }
                        }
                    }
                    
                    // Update lighting
                    updateLighting(in: root)
                }
            }
            .gesture(
                SpatialTapGesture()
                    .targetedToAnyEntity()
                    .onEnded { value in
                        handleTap(on: value.entity)
                    }
            )
            
            // Controls overlay
            VStack {
                VStack {
                    if showOptions {
                        VStack(spacing: 20) {
                            Text("Gallery Settings")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            VStack(alignment: .leading) {
                                Text("Gallery Style:")
                                    .font(.headline)
                                
                                Picker("Gallery Style", selection: $galleryStyle) {
                                    ForEach(GalleryStyle.allCases) { style in
                                        Text(style.rawValue).tag(style)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Lighting:")
                                    .font(.headline)
                                
                                Picker("Lighting Style", selection: $lightingStyle) {
                                    ForEach(LightingStyle.allCases) { style in
                                        Text(style.rawValue).tag(style)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                        .padding()
                        .frame(width: 400)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .padding()
                    }
                    
                    HStack {
                        Button(action: {
                            withAnimation {
                                showOptions.toggle()
                            }
                        }) {
                            Label(showOptions ? "Hide Controls" : "Show Controls", 
                                  systemImage: showOptions ? "chevron.up" : "chevron.down")
                                .padding(10)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 10)
                }
                
                Spacer()
                
                // Loading indicator
                if isLoading {
                    ProgressView("Loading Gallery...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                // Selected artwork info
                if let artwork = selectedArtwork {
                    HStack(spacing: 20) {
                        if !artwork.primaryImage.isEmpty {
                            AsyncImage(url: URL(string: artwork.primaryImage)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } placeholder: {
                                ProgressView()
                                    .frame(width: 100, height: 100)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text(artwork.title)
                                .font(.headline)
                                .lineLimit(1)
                            
                            if !artwork.artistDisplayName.isEmpty {
                                Text(artwork.artistDisplayName)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            
                            Text(artwork.objectDate)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button("View Details") {
                                openWindow(id: "artwork-detail", value: artwork)
                            }
                            .buttonStyle(.bordered)
                            .padding(.top, 5)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            selectedArtwork = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                    .frame(width: 400)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .padding()
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createWall(width: Float, height: Float, depth: Float) -> ModelEntity {
        let wallMesh = MeshResource.generateBox(width: width, height: height, depth: depth)
        let wallMaterial = createWallMaterial()
        let wall = ModelEntity(mesh: wallMesh, materials: [wallMaterial])
        wall.generateCollisionShapes(recursive: true)
        wall.components.set(PhysicsBodyComponent(massProperties: .default, mode: .static))
        return wall
    }
    
    private func createWallMaterial() -> RealityFoundation.Material {
        var material = SimpleMaterial(color: .white, roughness: 0.3, isMetallic: false)
        
        // Adjust wall material based on style
        switch galleryStyle {
        case .modern:
            material = SimpleMaterial(color: .white, roughness: 0.1, isMetallic: false)
        case .classical:
            material = SimpleMaterial(color: .init(red: 0.92, green: 0.9, blue: 0.85, alpha: 1.0), roughness: 0.5, isMetallic: false)
        case .minimalist:
            material = SimpleMaterial(color: .init(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0), roughness: 0.2, isMetallic: false)
        }
        
        return material
    }
    
    private func createFloorMaterial() -> RealityFoundation.Material {
        var material: RealityFoundation.Material
        
        // Create floor material based on style
        switch galleryStyle {
        case .modern:
            material = SimpleMaterial(color: .init(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0), roughness: 0.1, isMetallic: false)
        case .classical:
            // Marble-like floor for classical style
            material = SimpleMaterial(color: .init(red: 0.9, green: 0.88, blue: 0.84, alpha: 1.0), roughness: 0.2, isMetallic: true)
        case .minimalist:
            // Dark concrete-like floor for minimalist style
            material = SimpleMaterial(color: .init(red: 0.25, green: 0.25, blue: 0.25, alpha: 1.0), roughness: 0.7, isMetallic: false)
        }
        
        return material
    }
    
    private func addGalleryElements(to galleryRoot: Entity) {
        // Add decorative elements based on style
        switch galleryStyle {
        case .modern:
            // Add modern gallery elements
            // (e.g., minimalistic benches, lighting fixtures)
            addBenches(to: galleryRoot, style: .modern)
        case .classical:
            // Add classical gallery elements
            // (e.g., ornate benches, decorative moldings)
            addBenches(to: galleryRoot, style: .classical)
        case .minimalist:
            // Add minimalist gallery elements
            // (e.g., simple geometric benches)
            addBenches(to: galleryRoot, style: .minimalist)
        }
    }
    
    private func addBenches(to gallery: Entity, style: GalleryStyle) {
        // Create and add benches based on selected style
        let benchLength: Float = 1.5
        let benchWidth: Float = 0.5
        let benchHeight: Float = 0.4
        
        // Create bench mesh and material
        let benchMesh = MeshResource.generateBox(width: benchLength, height: benchHeight, depth: benchWidth)
        
        var benchMaterial: RealityFoundation.Material
        
        switch style {
        case .modern:
            benchMaterial = SimpleMaterial(color: .init(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0), roughness: 0.1, isMetallic: true)
        case .classical:
            benchMaterial = SimpleMaterial(color: .init(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0), roughness: 0.5, isMetallic: false)
        case .minimalist:
            benchMaterial = SimpleMaterial(color: .init(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0), roughness: 0.2, isMetallic: false)
        }
        
        // Create benches and position them
        let bench1 = ModelEntity(mesh: benchMesh, materials: [benchMaterial])
        bench1.transform.translation = SIMD3<Float>(0, benchHeight/2 - 1.5, 2)
        bench1.generateCollisionShapes(recursive: true)
        bench1.components.set(PhysicsBodyComponent(massProperties: .default, mode: .static))
        gallery.addChild(bench1)
        
        let bench2 = ModelEntity(mesh: benchMesh, materials: [benchMaterial])
        bench2.transform.translation = SIMD3<Float>(-3, benchHeight/2 - 1.5, 0)
        bench2.transform.rotation = simd_quatf(angle: .pi/2, axis: SIMD3<Float>(0, 1, 0))
        bench2.generateCollisionShapes(recursive: true)
        bench2.components.set(PhysicsBodyComponent(massProperties: .default, mode: .static))
        gallery.addChild(bench2)
        
        let bench3 = ModelEntity(mesh: benchMesh, materials: [benchMaterial])
        bench3.transform.translation = SIMD3<Float>(3, benchHeight/2 - 1.5, 0)
        bench3.transform.rotation = simd_quatf(angle: .pi/2, axis: SIMD3<Float>(0, 1, 0))
        bench3.generateCollisionShapes(recursive: true)
        bench3.components.set(PhysicsBodyComponent(massProperties: .default, mode: .static))
        gallery.addChild(bench3)
    }
    
    private func addLighting(to gallery: Entity) {
        // Add main directional light
        var directionalLight = DirectionalLightComponent()
        directionalLight.intensity = 2000
        
        // Set light color based on style
        updateLightProperties(&directionalLight)
        
        // Position the light
        let lightEntity = Entity()
        lightEntity.components.set(directionalLight)
        lightEntity.transform.translation = SIMD3<Float>(0, 2, 5)
        lightEntity.transform.rotation = simd_quatf(angle: -.pi/4, axis: SIMD3<Float>(1, 0, 0))
        lightEntity.name = "mainLight"
        gallery.addChild(lightEntity)
        
        // Add ambient light
        var ambientLight = DirectionalLightComponent()
        ambientLight.intensity = 500
        ambientLight.color = .white
        
        let ambientLightEntity = Entity()
        ambientLightEntity.components.set(ambientLight)
        gallery.addChild(ambientLightEntity)
        
        // Add accent lights for artwork
        addAccentLights(to: gallery)
    }
    
    private func updateLighting(in gallery: Entity) {
        // Update main light
        if let lightEntity = gallery.findEntity(named: "mainLight") {
            if var light = lightEntity.components[DirectionalLightComponent.self] {
                updateLightProperties(&light)
                lightEntity.components.set(light)
            }
        }
        
        // Update accent lights
        for i in 0..<10 {
            if let lightEntity = gallery.findEntity(named: "accentLight\(i)") {
                if var light = lightEntity.components[SpotLightComponent.self] {
                    updateAccentLightProperties(&light)
                    lightEntity.components.set(light)
                }
            }
        }
    }
    
    private func updateLightProperties(_ light: inout DirectionalLightComponent) {
        switch lightingStyle {
        case .natural:
            light.color = .init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            light.intensity = 2000
        case .warm:
            light.color = .init(red: 1.0, green: 0.9, blue: 0.8, alpha: 1.0)
            light.intensity = 2500
        case .dramatic:
            light.color = .init(red: 0.95, green: 0.95, blue: 1.0, alpha: 1.0)
            light.intensity = 3000
        case .cool:
            light.color = .init(red: 0.85, green: 0.95, blue: 1.0, alpha: 1.0)
            light.intensity = 2000
        }
    }
    
    private func updateAccentLightProperties(_ light: inout SpotLightComponent) {
        switch lightingStyle {
        case .natural:
            light.color = .white
            light.intensity = 2000
        case .warm:
            light.color = .init(red: 1.0, green: 0.9, blue: 0.8, alpha: 1.0)
            light.intensity = 1800
        case .dramatic:
            light.color = .init(red: 0.95, green: 0.95, blue: 1.0, alpha: 1.0)
            light.intensity = 3000
        case .cool:
            light.color = .init(red: 0.85, green: 0.95, blue: 1.0, alpha: 1.0)
            light.intensity = 2000
        }
    }
    
    private func addAccentLights(to gallery: Entity) {
        // Add spot lights for artwork
        for i in 0..<10 {
            var spotLight = SpotLightComponent()
            spotLight.intensity = 1000
            spotLight.innerAngleInDegrees = 30
            spotLight.outerAngleInDegrees = 45
            spotLight.attenuationRadius = 7
            
            let lightEntity = Entity()
            lightEntity.name = "accentLight\(i)"
            lightEntity.components.set(spotLight)
            
            // Will position these when artwork is placed
            lightEntity.transform.translation = SIMD3<Float>(Float(i) * 1.5 - 7, 2, -3)
            lightEntity.transform.rotation = simd_quatf(angle: -.pi/4, axis: SIMD3<Float>(1, 0, 0))
            
            gallery.addChild(lightEntity)
        }
    }
    
    private func loadFeaturedArtworks(galleryRoot: Entity, content: RealityViewContent) async {
        // Load featured artworks from several key departments
        let departmentIds = [1, 11, 21] // Example department IDs (American Decorative Arts, European Paintings, Medieval Art)
        var allArtworks: [ObjectDetails] = []
        
        for departmentId in departmentIds {
            do {
                let result = try await metMuseumClient.fetchObjects(departmentId: departmentId)
                let objectIds = Array(result.allAsInt.prefix(10)) // Get 10 objects from each department
                
                for id in objectIds {
                    do {
                        if let cachedObject = await ObjectCache.shared.object(for: id) {
                            allArtworks.append(cachedObject)
                        } else {
                            let objectDetails = try await metMuseumClient.fetchObjectDetails(objectID: id)
                            if !objectDetails.primaryImage.isEmpty {
                                allArtworks.append(objectDetails)
                                await ObjectCache.shared.cache(objectDetails)
                            }
                        }
                    } catch {
                        print("Error fetching object \(id): \(error)")
                    }
                }
            } catch {
                print("Error fetching objects for department \(departmentId): \(error)")
            }
        }
        
        await MainActor.run {
            featuredArtworks = allArtworks.shuffled().prefix(15).map { $0 } // Randomly select 15 artworks
        }
        
        // Place artworks on walls
        await placeArtworks(artworks: featuredArtworks, in: galleryRoot, content: content)
    }
    
    private func placeArtworks(artworks: [ObjectDetails], in gallery: Entity, content: RealityViewContent) async {
        // Divide artworks between the three walls
        let artworksPerWall = (artworks.count + 2) / 3
        
        // Back wall gets most artworks
        let backWallArtworks = Array(artworks.prefix(artworksPerWall))
        await placeArtworksOnWall(backWallArtworks, wallPosition: SIMD3<Float>(0, 0, -7.45), wallRotation: identityQuaternion, in: gallery, content: content)
        
        // Left wall
        let leftWallStartIndex = min(artworksPerWall, artworks.count)
        let leftWallEndIndex = min(2 * artworksPerWall, artworks.count)
        let leftWallArtworks = Array(artworks[leftWallStartIndex..<leftWallEndIndex])
        await placeArtworksOnWall(leftWallArtworks, wallPosition: SIMD3<Float>(-7.45, 0, 0), wallRotation: simd_quatf(angle: .pi/2, axis: SIMD3<Float>(0, 1, 0)), in: gallery, content: content)
        
        // Right wall
        if leftWallEndIndex < artworks.count {
            let rightWallArtworks = Array(artworks[leftWallEndIndex..<artworks.count])
            await placeArtworksOnWall(rightWallArtworks, wallPosition: SIMD3<Float>(7.45, 0, 0), wallRotation: simd_quatf(angle: -.pi/2, axis: SIMD3<Float>(0, 1, 0)), in: gallery, content: content)
        }
    }
    
    private func placeArtworksOnWall(_ artworks: [ObjectDetails], wallPosition: SIMD3<Float>, wallRotation: simd_quatf, in gallery: Entity, content: RealityViewContent) async {
        let spacing: Float = 2.5 // Spacing between artworks
        let startX: Float = -Float(artworks.count - 1) * spacing / 2
        let height: Float = 0.5 // Height above floor
        
        for (index, artwork) in artworks.enumerated() {
            do {
                let xPosition = startX + Float(index) * spacing
                var position = SIMD3<Float>(xPosition, height, 0)
                
                // Apply wall rotation to position
                if wallRotation != identityQuaternion {
                    position = wallRotation.act(position)
                }
                
                // Add wall position
                position += wallPosition
                
                // Create an artwork entity
                let artworkEntity = try await createArtworkEntity(artwork: artwork)
                artworkEntity.transform.translation = position
                artworkEntity.transform.rotation = wallRotation
                
                // Set user data to identify the artwork
                artworkEntity.name = "artwork_\(artwork.objectID)"
                
                gallery.addChild(artworkEntity)
                
                // Position accent light above artwork
                if let lightEntity = gallery.findEntity(named: "accentLight\(index)") {
                    var lightPosition = position
                    lightPosition.y += 2.0 // Raise light above artwork
                    
                    if wallRotation == identityQuaternion {
                        // Back wall
                        lightPosition.z += 1.0 // Move light forward
                    } else if wallRotation.angle == .pi/2 {
                        // Left wall
                        lightPosition.x += 1.0 // Move light to the right
                    } else {
                        // Right wall
                        lightPosition.x -= 1.0 // Move light to the left
                    }
                    
                    lightEntity.transform.translation = lightPosition
                    
                    // Rotate light to point at the artwork
                    if wallRotation == identityQuaternion {
                        // Back wall
                        lightEntity.transform.rotation = simd_quatf(angle: -.pi/4, axis: SIMD3<Float>(1, 0, 0))
                    } else if wallRotation.angle == .pi/2 {
                        // Left wall
                        lightEntity.transform.rotation = simd_quatf(angle: -.pi/4, axis: SIMD3<Float>(1, 0, 0))
                            * simd_quatf(angle: -.pi/2, axis: SIMD3<Float>(0, 1, 0))
                    } else {
                        // Right wall
                        lightEntity.transform.rotation = simd_quatf(angle: -.pi/4, axis: SIMD3<Float>(1, 0, 0))
                            * simd_quatf(angle: .pi/2, axis: SIMD3<Float>(0, 1, 0))
                    }
                }
            } catch {
                print("Error placing artwork: \(error)")
            }
        }
    }
    
    private func createArtworkEntity(artwork: ObjectDetails) async throws -> Entity {
        let artworkRoot = Entity()
        
        // Create the artwork image plane
        guard let imageUrl = URL(string: artwork.primaryImage) else {
            throw NSError(domain: "ArtworkError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid image URL"])
        }
        
        let imageData = try await URLSession.shared.data(from: imageUrl).0
        guard let uiImage = UIImage(data: imageData) else {
            throw NSError(domain: "ArtworkError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])
        }
        
        let texture = try await TextureResource(contentsOf: imageUrl)
        
        // Calculate aspect ratio
        let aspectRatio = uiImage.size.width / uiImage.size.height
        
        // Default size for artwork (height is fixed, width adjusts by aspect ratio)
        let artworkHeight: Float = 1.5
        let artworkWidth: Float = Float(aspectRatio) * artworkHeight
        
        // Create the artwork plane
        let artworkMesh = MeshResource.generatePlane(width: artworkWidth, height: artworkHeight)
        var material = UnlitMaterial()
        material.color = .init(texture: .init(texture))
        let artworkPlane = ModelEntity(mesh: artworkMesh, materials: [material])
        
        // Create the frame based on gallery style
        let frameEntity = createArtworkFrame(width: artworkWidth, height: artworkHeight)
        
        // Add frame behind artwork
        frameEntity.transform.translation.z = -0.01
        artworkRoot.addChild(frameEntity)
        
        // Add artwork plane
        artworkRoot.addChild(artworkPlane)
        
        // Add label below artwork
        let labelEntity = createArtworkLabel(artwork: artwork, width: artworkWidth)
        labelEntity.transform.translation = SIMD3<Float>(0, -artworkHeight/2 - 0.15, 0)
        artworkRoot.addChild(labelEntity)
        
        // Add information panel
        let infoPanelWidth: Float = 0.2
        let infoPanelHeight: Float = 0.2
        
        let infoPanelMesh = MeshResource.generatePlane(width: infoPanelWidth, height: infoPanelHeight)
        var infoPanelMaterial = UnlitMaterial()
        
        // Create info icon
        let infoIconConfig = UIImage.SymbolConfiguration(pointSize: 50, weight: .regular)
        let infoIcon = UIImage(systemName: "info.circle.fill", withConfiguration: infoIconConfig)!
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))
        let infoImage = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
            infoIcon.draw(in: CGRect(origin: CGPoint(x: 25, y: 25), size: CGSize(width: 50, height: 50)))
        }
        
        let infoTexture = try await TextureResource(image: infoImage.cgImage!, options: .init(semantic: .color))
        infoPanelMaterial.color = .init(texture: .init(infoTexture))
        
        let infoPanel = ModelEntity(mesh: infoPanelMesh, materials: [infoPanelMaterial])
        infoPanel.transform.translation = SIMD3<Float>(artworkWidth/2 + infoPanelWidth/2 + 0.05, -artworkHeight/2 + infoPanelHeight/2, 0)
        artworkRoot.addChild(infoPanel)
        
        return artworkRoot
    }
    
    private func createArtworkFrame(width: Float, height: Float) -> Entity {
        // Frame dimensions
        let frameThickness: Float = 0.05
        let frameDepth: Float = 0.02
        
        // Create frame parts
        let outerFrameMesh = MeshResource.generateBox(width: width + frameThickness * 2, height: height + frameThickness * 2, depth: frameDepth)
        let innerFrameMesh = MeshResource.generateBox(width: width, height: height, depth: frameDepth + 0.02)
        
        // Create frame entity
        let frameEntity = Entity()
        
        // Frame material based on gallery style
        var frameMaterial: RealityFoundation.Material
        
        switch galleryStyle {
        case .modern:
            frameMaterial = SimpleMaterial(color: .white, roughness: 0.1, isMetallic: false)
        case .classical:
            frameMaterial = SimpleMaterial(color: .init(red: 0.85, green: 0.7, blue: 0.25, alpha: 1.0), roughness: 0.3, isMetallic: true)
        case .minimalist:
            frameMaterial = SimpleMaterial(color: .init(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0), roughness: 0.2, isMetallic: false)
        }
        
        // Create outer frame
        let outerFrame = ModelEntity(mesh: outerFrameMesh, materials: [frameMaterial])
        frameEntity.addChild(outerFrame)
        
        // Create inner cutout (using a subtractive model)
        let innerFrame = ModelEntity(mesh: innerFrameMesh)
        outerFrame.addChild(innerFrame)
        innerFrame.transform.translation.z = 0.01
        
        return frameEntity
    }
    
    private func createArtworkLabel(artwork: ObjectDetails, width: Float) -> Entity {
        // Create label dimensions
        let labelWidth: Float = width
        let labelHeight: Float = 0.25
        
        // Create text for label
        let text1 = "\(artwork.title)"
        let text2 = artwork.artistDisplayName.isEmpty ? artwork.objectDate : "\(artwork.artistDisplayName), \(artwork.objectDate)"
        
        // Create a UIImage with the text
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1024, height: 256))
        let labelImage = renderer.image { context in
            // Fill background
            UIColor.init(white: 0.9, alpha: 0.8).setFill()
            context.fill(CGRect(origin: .zero, size: CGSize(width: 1024, height: 256)))
            
            // Draw text
            let titleFont = UIFont.systemFont(ofSize: 40, weight: .bold)
            let subtitleFont = UIFont.systemFont(ofSize: 30, weight: .regular)
            
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.black
            ]
            
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: subtitleFont,
                .foregroundColor: UIColor.darkGray
            ]
            
            // Draw title
            let titleRect = CGRect(x: 20, y: 20, width: 984, height: 100)
            text1.draw(in: titleRect, withAttributes: titleAttributes)
            
            // Draw subtitle
            let subtitleRect = CGRect(x: 20, y: 120, width: 984, height: 100)
            text2.draw(in: subtitleRect, withAttributes: subtitleAttributes)
        }
        
        // Create label entity
        do {
            let labelMesh = MeshResource.generatePlane(width: labelWidth, height: labelHeight)
            let labelTexture = try TextureResource(image: labelImage.cgImage!, options: .init(semantic: .color))
            var labelMaterial = UnlitMaterial()
            labelMaterial.color = .init(texture: .init(labelTexture))
            
            return ModelEntity(mesh: labelMesh, materials: [labelMaterial])
        } catch {
            print("Error creating artwork label: \(error)")
            
            // Fallback to simple label
            let labelMesh = MeshResource.generatePlane(width: labelWidth, height: labelHeight)
            let labelMaterial = SimpleMaterial(color: .init(red: 0.9, green: 0.9, blue: 0.9, alpha: 0.8), roughness: 0.1, isMetallic: false)
            
            return ModelEntity(mesh: labelMesh, materials: [labelMaterial])
        }
    }
    
    private func handleTap(on entity: Entity) {
        // Find the parent artwork entity (might be tapping on a child entity)
        var currentEntity: Entity? = entity
        var artworkId: Int?
        
        while currentEntity != nil {
            if let name = currentEntity?.name, name.starts(with: "artwork_") {
                let idString = name.dropFirst("artwork_".count)
                artworkId = Int(idString)
                break
            }
            currentEntity = currentEntity?.parent
        }
        
        if let id = artworkId {
            // Find the corresponding artwork
            if let artwork = featuredArtworks.first(where: { $0.objectID == id }) {
                // Set as selected artwork
                selectedArtwork = artwork
            }
        }
    }
}

#Preview {
    MetGalleryImmersiveView()
        .environment(AppModel())
} 