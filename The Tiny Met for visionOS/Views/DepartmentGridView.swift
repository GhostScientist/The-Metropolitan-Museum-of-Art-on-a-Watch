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
                    // Background image based on department
                    if let imageName = departmentImageName {
                        Image(imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 320)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .overlay {
                                // Dark overlay for better text readability
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(.black.opacity(0.4))
                            }
                    } else {
                        // Fallback gradient background
                        LinearGradient(
                            colors: departmentGradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: 320)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }
                    
                    // Department icon and info overlay
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: departmentIcon)
                            .font(.system(size: 60))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.6), radius: 3)
                        
                        VStack(spacing: 12) {
                            Text(department.displayName)
                                .font(.title)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .lineLimit(4)
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.8), radius: 3)
                            
                            Text("Explore Collection")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.9))
                                .shadow(color: .black.opacity(0.6), radius: 2)
                        }
                        
                        Spacer()
                    }
                    .padding(30)
                }
            }
            .frame(height: 320)
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
    
    private var departmentImageName: String? {
        // Map department ID to image names from your watchOS app
        switch department.departmentId {
        case 1: return "1"    // The American Wing
        case 3: return "3"    // Ancient Near Eastern Art
        case 4: return "4"    // Arms and Armor
        case 5: return "5"    // Arts of Africa, Oceania, and the Americas
        case 6: return "6"    // Asian Art
        case 7: return "7"    // The Cloisters
        case 8: return "8"    // The Costume Institute
        case 9: return "9"    // Drawings and Prints
        case 10: return "10"  // Egyptian Art
        case 11: return "11"  // European Paintings
        case 12: return "12"  // European Sculpture and Decorative Arts
        case 13: return "13"  // Greek and Roman Art
        case 14: return "14"  // Islamic Art
        case 15: return "15"  // The Robert Lehman Collection
        case 16: return "16"  // The Libraries
        case 17: return "17"  // Medieval Art
        case 18: return "18"  // Musical Instruments
        case 19: return "19"  // Photographs
        case 20: return "20"  // Modern Art
        default: return nil
        }
    }
    
    private var departmentGradientColors: [Color] {
        let name = department.displayName.lowercased()
        
        switch name {
        case let n where n.contains("american"):
            return [.red, .blue]
        case let n where n.contains("european"):
            return [.purple, .blue]
        case let n where n.contains("asian"):
            return [.orange, .red]
        case let n where n.contains("egyptian"):
            return [.yellow, .orange]
        case let n where n.contains("greek") || n.contains("roman"):
            return [.blue, .cyan]
        case let n where n.contains("islamic"):
            return [.teal, .green]
        case let n where n.contains("medieval"):
            return [.purple, .indigo]
        case let n where n.contains("modern"):
            return [.pink, .purple]
        case let n where n.contains("costume") || n.contains("fashion"):
            return [.pink, .red]
        case let n where n.contains("arms") || n.contains("armor"):
            return [.gray, .black]
        default:
            return [.blue, .purple]
        }
    }
    
    private var departmentIcon: String {
        let name = department.displayName.lowercased()
        
        switch name {
        case let n where n.contains("american"):
            return "flag.fill"
        case let n where n.contains("european"):
            return "building.columns.fill"
        case let n where n.contains("asian"):
            return "building.2.fill"
        case let n where n.contains("egyptian"):
            return "pyramid"
        case let n where n.contains("greek") || n.contains("roman"):
            return "building.columns"
        case let n where n.contains("islamic"):
            return "moon.stars.fill"
        case let n where n.contains("medieval"):
            return "crown.fill"
        case let n where n.contains("modern"):
            return "square.stack.3d.up.fill"
        case let n where n.contains("contemporary"):
            return "paintbrush.pointed.fill"
        case let n where n.contains("arms") || n.contains("armor"):
            return "shield.fill"
        case let n where n.contains("costume") || n.contains("fashion"):
            return "tshirt.fill"
        case let n where n.contains("musical"):
            return "music.note"
        case let n where n.contains("photograph"):
            return "camera.fill"
        case let n where n.contains("print") || n.contains("drawing"):
            return "pencil.and.outline"
        default:
            return "building.columns.fill"
        }
    }
    
    private var departmentGlowColor: Color {
        departmentGradientColors.first ?? .blue
    }
}

#Preview {
    DepartmentGridView()
        .environment(AppModel())
}