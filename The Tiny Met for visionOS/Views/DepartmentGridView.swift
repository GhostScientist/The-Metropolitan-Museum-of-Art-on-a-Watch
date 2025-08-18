//
//  DepartmentGridView.swift
//  The Tiny Met for visionOS
//
//  Created by Dakota Kim on 8/18/25.
//

import SwiftUI

struct DepartmentGridView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom header
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "building.columns.fill")
                        .font(.title)
                        .foregroundStyle(.blue)
                    
                    Text("The Metropolitan Museum")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button {
                        Task {
                            await openImmersiveSpace(id: appModel.immersiveSpaceID)
                        }
                    } label: {
                        Label("Enter Gallery", systemImage: "visionpro.fill")
                    }
                    .disabled(appModel.immersiveSpaceState == .open)
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal, 60)
                .padding(.top, 20)
                
                Text("Explore World-Class Art Collections")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 60)
                    .padding(.bottom, 20)
            }
            .background(.ultraThinMaterial, in: Rectangle())
            
            Group {
                if appModel.isLoadingDepartments {
                    EnhancedLoadingView(message: "Loading The Met's Departments...")
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                    
                } else if let errorMessage = appModel.errorMessage {
                    VStack(spacing: 30) {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 100))
                            .foregroundStyle(.red)
                        
                        Text(errorMessage)
                            .font(.title2)
                            .multilineTextAlignment(.center)
                        
                        Button("Retry") {
                            Task {
                                await appModel.fetchDepartments()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 40),
                            GridItem(.flexible(), spacing: 40)
                        ], spacing: 40) {
                            ForEach(appModel.departments) { department in
                                DepartmentGridCard(department: department)
                                    .floatingPhysics()
                                    .enhancedFeedback(onHover: true, onTap: true)
                            }
                        }
                        .padding(60)
                    }
                    .refreshable {
                        await appModel.fetchDepartments()
                    }
                }
            }
        }
    }
}

struct DepartmentGridCard: View {
    @Environment(AppModel.self) private var appModel
    let department: Department
    @State private var isHovered = false
    @State private var scale: CGFloat = 1.0
    @State private var rotationY: Double = 0
    @State private var showGlow = false
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 0.95
                rotationY = 5
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    scale = 1.0
                    rotationY = 0
                }
                appModel.selectedDepartment = department
            }
        } label: {
            VStack(spacing: 0) {
                // Department image background
                ZStack {
                    // Department image from Assets (same as watchOS)
                    GeometryReader { geometry in
                        Image(departmentImageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(
                                width: geometry.size.width,
                                height: geometry.size.height
                            )
                            .clipped()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay {
                            // Dark overlay for better text readability
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(.black.opacity(0.3))
                        }
                    
                    // Department info overlay
                    VStack {
                        Spacer()
                        
                        VStack(spacing: 12) {
                            Text(department.displayName)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .lineLimit(4)
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.8), radius: 4)
                            
                            Text("Explore Collection")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundStyle(.white.opacity(0.9))
                                .shadow(color: .black.opacity(0.6), radius: 2)
                        }
                        
                        Spacer(minLength: 30)
                    }
                    .padding(30)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 320)
            .clipped()
        }
        .buttonStyle(.plain)
        .scaleEffect(scale)
        .rotation3DEffect(
            .degrees(rotationY),
            axis: (x: 0, y: 1, z: 0)
        )
        .shadow(
            color: showGlow ? departmentGlowColor : .clear,
            radius: showGlow ? 20 : 0,
            x: 0,
            y: 0
        )
        .onHover { hovering in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                isHovered = hovering
                scale = hovering ? 1.08 : 1.0
                rotationY = hovering ? -3 : 0
                showGlow = hovering
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: appModel.selectedDepartment?.departmentId)
    }
    
    private var departmentImageName: String {
        // Use Asset images named after department ID (same as watchOS)
        return "\(department.departmentId)"
    }
    
    private var departmentGlowColor: Color {
        // Use a sophisticated glow based on department theme
        let name = department.displayName.lowercased()
        
        switch name {
        case let n where n.contains("american"):
            return .blue
        case let n where n.contains("european"):
            return .purple
        case let n where n.contains("asian"):
            return .orange
        case let n where n.contains("egyptian"):
            return .yellow
        case let n where n.contains("greek") || n.contains("roman"):
            return .cyan
        case let n where n.contains("islamic"):
            return .teal
        case let n where n.contains("medieval"):
            return .indigo
        case let n where n.contains("modern"):
            return .pink
        case let n where n.contains("costume") || n.contains("fashion"):
            return .red
        case let n where n.contains("arms") || n.contains("armor"):
            return .gray
        default:
            return .blue
        }
    }
}

#Preview {
    DepartmentGridView()
        .environment(AppModel())
}