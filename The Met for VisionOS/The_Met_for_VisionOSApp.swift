//
//  The_Met_for_VisionOSApp.swift
//  The Met for VisionOS
//
//  Created by Dakota Kim on 1/20/25.
//

import SwiftUI
import TheMetUtilities


@main
struct The_Met_for_VisionOSApp: App {

    @State private var appModel = AppModel()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    var body: some Scene {
        WindowGroup {
            if !hasCompletedOnboarding {
                OnboardingView(onComplete: {
                    hasCompletedOnboarding = true
                })
            } else {
                MetSpatialExperienceView()
                    .environment(appModel)
            }
        }
        .windowStyle(.plain)
        .defaultSize(width: 500, height: 700)

        WindowGroup(id: "artwork-detail", for: ObjectDetails.self) { $objectDetails in
            if let objectDetails = objectDetails {
                EnhancedArtworkDetailView(objectDetails: objectDetails)
                    .environment(appModel)
            }
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 600, height: 800, depth: 100)

        WindowGroup(id: "image-viewer", for: String.self) { $imageURL in
            if let imageURL {
                ImmersiveArtworkView(imageURL: imageURL)
                    .environment(appModel)
            }
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 800, height: 600, depth: 200)

        WindowGroup(id: appModel.immersiveSpaceID) {
            MetGalleryImmersiveView()
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
        .windowStyle(.plain)
        .defaultSize(width: 800, height: 600)
    }
}
