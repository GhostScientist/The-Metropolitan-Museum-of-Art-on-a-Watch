//
//  DepartmentListView.swift
//  The Metropolitan Museum of Art on a Watch Watch App
//
//  Created by Dakota Kim on 4/2/24.
//

import SwiftUI

struct Object: Identifiable {
    let id: Int
    let title: String
    let objectName: String
    
    var objectID: Int { id }
}

struct DepartmentListView: View {
    @State private var objects: [ObjectDetails] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    private let metMuseumClient = MetMuseumClient()
    
    var departmentId: Int
    
    var body: some View {
        Group {
            if isLoading {
                Text("Loading")
            } else {
                List(objects) { object in
                    NavigationLink(destination: Text("\(object)")) {
                        Text(object.title)
                    }
                }
                .navigationTitle("Departments")
            }
        }.onAppear {
            fetchObjects()
        }
    }
    
    private func fetchObjects() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let objectIDs = try await metMuseumClient.fetchObjects(departmentId: departmentId)
                let firstTenObjectIDs = objectIDs.firstTen
                
                objects = try await withThrowingTaskGroup(of: ObjectDetails.self) { group in
                    for objectID in firstTenObjectIDs {
                        print(objectID)
                        group.addTask {
                            try await metMuseumClient.fetchObjectDetails(objectID: objectID)
                        }
                    }
                    
                    var fetchedObjects: [ObjectDetails] = []
                    for try await object in group {
                        fetchedObjects.append(object)
                    }
                    return fetchedObjects
                }
                
                isLoading = false
            } catch {
                if error.isInternetConnectionError {
                    errorMessage = "Awwww no wifi UWU"
                } else {
                    errorMessage = "Failed to fetch departments"
                }
                isLoading = false
            }
        }
    }
    
    private func fetchObject(objectID: Int) async throws -> Object {
        let objectDetails = try await metMuseumClient.fetchObjectDetails(objectID: objectID)
        return Object(id: objectDetails.objectID, title: objectDetails.title, objectName: objectDetails.objectName)
    }
}

#Preview {
    DepartmentListView(departmentId: 3)
}
