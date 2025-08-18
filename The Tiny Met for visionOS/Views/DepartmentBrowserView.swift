//
//  DepartmentBrowserView.swift
//  The Tiny Met for visionOS
//
//  Created by Dakota Kim on 8/18/25.
//

import SwiftUI
import RealityKit

struct DepartmentBrowserView_Legacy: View {
    @Environment(AppModel.self) private var appModel
    
    var body: some View {
        Group {
            if appModel.isLoadingDepartments {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading Museum Departments...")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            } else if let errorMessage = appModel.errorMessage {
                VStack(spacing: 20) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 60))
                        .foregroundStyle(.red)
                    
                    Text(errorMessage)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Button("Retry") {
                        Task {
                            await appModel.fetchDepartments()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 20),
                        GridItem(.flexible(), spacing: 20)
                    ], spacing: 20) {
                        ForEach(appModel.departments) { department in
                            DepartmentCardView(department: department)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .navigationTitle("Museum Departments")
        .refreshable {
            await appModel.fetchDepartments()
        }
    }
}

struct DepartmentCardView: View {
    @Environment(AppModel.self) private var appModel
    let department: Department
    
    var body: some View {
        Button {
            appModel.selectedDepartment = department
        } label: {
            VStack(alignment: .leading, spacing: 15) {
                // Department icon based on type
                Image(systemName: departmentIcon)
                    .font(.system(size: 40))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(department.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                    
                    Text("\(department.departmentId)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
            .frame(width: 280, height: 200)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
        .rotation3DEffect(.degrees(5), axis: (x: 1, y: 0, z: 0))
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
}

#Preview {
    NavigationSplitView {
        DepartmentBrowserView_Legacy()
    } detail: {
        Text("Select a department")
    }
    .environment(AppModel())
}