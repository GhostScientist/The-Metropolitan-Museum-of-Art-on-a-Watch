//
//  ContentView.swift
//  The Tiny Met for visionOS
//
//  Created by Dakota Kim on 8/18/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @StateObject private var audioManager = SpatialAudioManager.shared

    var body: some View {
        @Bindable var appModel = appModel
        
        NavigationStack {
            Group {
                if let selectedDepartment = appModel.selectedDepartment {
                    ArtworkGalleryView(department: selectedDepartment)
                        .navigationBarBackButtonHidden(true)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button {
                                    audioManager.playTransitionSound()
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        appModel.selectedDepartment = nil
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "chevron.left.circle.fill")
                                            .font(.title2)
                                        Text("Departments")
                                            .font(.headline)
                                    }
                                    .foregroundStyle(.primary)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(.regularMaterial, in: Capsule())
                                .shadow(radius: 4)
                                .scaleEffect(1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: appModel.selectedDepartment)
                            }
                            
                            ToolbarItem(placement: .principal) {
                                Text(selectedDepartment.displayName)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                            }
                        }
                } else {
                    DepartmentGridView()
                }
            }
        }
        .task {
            if appModel.departments.isEmpty {
                await appModel.fetchDepartments()
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
