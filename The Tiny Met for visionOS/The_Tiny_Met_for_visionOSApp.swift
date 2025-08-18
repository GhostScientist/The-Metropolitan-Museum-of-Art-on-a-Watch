//
//  The_Tiny_Met_for_visionOSApp.swift
//  The Tiny Met for visionOS
//
//  Created by Dakota Kim on 8/18/25.
//

import SwiftUI

@main
struct The_Tiny_Met_for_visionOSApp: App {

    @State private var appModel = AppModel()

    var body: some Scene {
        // Main browsing interface
        WindowGroup {
            ContentView()
                .environment(appModel)
        }
        
        // 3D Volume Gallery for departments
        WindowGroup("VolumeGallery", id: "VolumeGallery", for: Int.self) { $departmentId in
            if let departmentId = departmentId,
               let department = appModel.departments.first(where: { $0.departmentId == departmentId }) {
                VolumeGalleryView(department: department)
                    .environment(appModel)
            } else {
                Text("Gallery not found")
                    .foregroundStyle(.secondary)
            }
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 1.2, height: 0.8, depth: 1.0, in: .meters)
        
        // Individual artwork detail windows
        WindowGroup("ArtworkDetail", id: "ArtworkDetail", for: Int.self) { $objectID in
            if let objectID = objectID {
                ArtworkDetailView(objectID: objectID)
                    .environment(appModel)
            } else {
                Text("Artwork not found")
                    .foregroundStyle(.secondary)
            }
        }
        .windowResizability(.contentSize)

        // Immersive gallery space
        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveGalleryView()
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
     }
}
