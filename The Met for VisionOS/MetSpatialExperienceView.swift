//
//  MetSpatialExperienceView.swift
//  The Met for VisionOS
//
//  Created by Dakota Kim on 1/20/25.
//

import SwiftUI
import RealityKit
import TheMetUtilities

struct MetSpatialExperienceView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    @State private var departments: [Department] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var selectedDepartment: Department?
    @State private var showGalleryButton = false
    @State private var rotationAngles: [Double] = []
    @State private var searchText = ""
    
    private let metMuseumClient = MetMuseumClient()
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.1)
                .ignoresSafeArea()
            
            VStack {
                // Header
                HStack {
                    Text("The Metropolitan Museum of Art")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    // Toggle immersive gallery button
                    if showGalleryButton {
                        Button {
                            toggleImmersiveSpace()
                        } label: {
                            Label(
                                appModel.immersiveSpaceState == .open ? "Exit Gallery" : "Enter Gallery",
                                systemImage: appModel.immersiveSpaceState == .open ? "rectangle.portrait.and.arrow.right" : "building.columns.fill"
                            )
                        }
                        .buttonStyle(.bordered)
                        .disabled(appModel.immersiveSpaceState == .inTransition)
                    }
                }
                .padding()
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search the collection...", text: $searchText)
                        .textFieldStyle(.plain)
                        .submitLabel(.search)
                        .onSubmit {
                            // Handle search
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)
                
                // Main content
                Group {
                    if isLoading && departments.isEmpty {
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Loading departments...")
                                .font(.headline)
                                .padding()
                        }
                    } else if let error = errorMessage {
                        VStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.yellow)
                                .padding()
                            
                            Text(error)
                                .font(.headline)
                            
                            Button("Try Again") {
                                fetchDepartments()
                            }
                            .buttonStyle(.bordered)
                            .padding()
                        }
                    } else {
                        // Department grid
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 250, maximum: 300), spacing: 20)], spacing: 20) {
                                ForEach(departments.indices, id: \.self) { index in
                                    DepartmentCard(
                                        department: departments[index],
                                        rotationAngle: rotationAngles.count > index ? rotationAngles[index] : 0
                                    )
                                    .onTapGesture {
                                        selectedDepartment = departments[index]
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
        }
        .onAppear {
            fetchDepartments()
            
            // Show gallery button after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showGalleryButton = true
                }
            }
        }
        .sheet(isPresented: Binding<Bool>(
            get: { selectedDepartment != nil },
            set: { if !$0 { selectedDepartment = nil } }
        )) {
            if let department = selectedDepartment {
                EnhancedDepartmentView(department: department)
                    .environment(appModel)
            }
        }
    }
    
    private func fetchDepartments() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                departments = try await metMuseumClient.fetchDepartments().departments
                
                // Generate random rotation angles for each department
                rotationAngles = departments.map { _ in Double.random(in: -5...5) }
                
                isLoading = false
            } catch {
                if error.isInternetConnectionError {
                    errorMessage = "No internet connection. Please check your connection and try again."
                } else {
                    errorMessage = "Failed to fetch departments. Please try again."
                }
                isLoading = false
            }
        }
    }
    
    private func toggleImmersiveSpace() {
        Task {
            switch appModel.immersiveSpaceState {
            case .open:
                appModel.immersiveSpaceState = .inTransition
                await dismissImmersiveSpace()
                
            case .closed:
                appModel.immersiveSpaceState = .inTransition
                switch await openImmersiveSpace(id: appModel.immersiveSpaceID) {
                case .opened:
                    break
                case .userCancelled, .error:
                    fallthrough
                @unknown default:
                    appModel.immersiveSpaceState = .closed
                }
                
            case .inTransition:
                break
            }
        }
    }
}

struct DepartmentCard: View {
    let department: Department
    let rotationAngle: Double
    
    var body: some View {
        VStack(alignment: .leading) {
            // Department icon
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.1, green: 0.1, blue: 0.3),
                                Color(red: 0.3, green: 0.1, blue: 0.5)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 120)
                
                // 3D icon
                RealityView { content in
                    // Create a simple 3D model for the department
                    let mesh = MeshResource.generateSphere(radius: 0.05)
                    let material = SimpleMaterial(color: .white, roughness: 0.2, isMetallic: true)
                    let entity = ModelEntity(mesh: mesh, materials: [material])
                    
                    // Add to content
                    content.add(entity)
                }
                .frame(width: 80, height: 80)
            }
            
            // Department name
            Text(department.displayName)
                .font(.headline)
                .fontWeight(.bold)
                .lineLimit(2)
                .padding(.top, 8)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .rotation3DEffect(.degrees(rotationAngle), axis: (x: 0, y: 1, z: 0))
        .shadow(radius: 5)
    }
}

#Preview {
    MetSpatialExperienceView()
        .environment(AppModel())
} 