//
//  ContentView.swift
//  The Met for VisionOS
//
//  Created by Dakota Kim on 12/1/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @State private var departments: [Department] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var selectedTab = 0
    
    private let metMuseumClient = MetMuseumClient()
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading")
                } else if errorMessage != nil {
                    Text(errorMessage!)
                } else {
                    TabView(selection: $selectedTab) {
                        ForEach(departments.indices, id: \.self) { index in
                            let department = departments[index]
                            NavigationLink(destination: DepartmentListView(department: department)) {
                                Text(department.displayName as String)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                                    .padding()
                                    .tag(index)
                            }
                            
                            
                        }
                        
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                }
            }
        }
        .onAppear {
            fetchDepartments()
        }
    }
    
    private func getBackgroundColor(for tabIndex: Int) -> Color {
        guard tabIndex >= 0 && tabIndex < departments.count else {
            return Color.clear
        }
        
        let colors: [Color] = [.red, .green, .blue, .yellow]
        return colors[tabIndex % colors.count]
    }
    
    private func fetchDepartments() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                departments = try await metMuseumClient.fetchDepartments().departments
                print("Deps: \(departments)")
                isLoading = false
            } catch {
                
                    errorMessage = "Failed to fetch departments"
                
                isLoading = false
            }
        }
    }
}


#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}