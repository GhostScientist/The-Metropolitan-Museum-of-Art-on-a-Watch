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
    
    var department: Department
    
    var body: some View {
        Group {
            if isLoading {
                Text("Loading")
            } else {
                List(objects) { object in
                    NavigationLink(destination: ObjectDetailView(objectDetails: object)) {
                        Text(object.title)
                    }
                }
                .navigationTitle(department.displayName)
            }
        }.onFirstAppear {
            fetchObjects()
        }
    }
    
    private func fetchObjects() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let objectIDs = try await metMuseumClient.fetchObjects(departmentId: department.departmentId)
                let firstTenObjectIDs = objectIDs.allAsInt
                
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
    DepartmentListView(department: Department(departmentId: 1, displayName: "American Decorative Arts"))
}



public struct OnFirstAppearModifier: ViewModifier {

    private let onFirstAppearAction: () -> ()
    @State private var hasAppeared = false
    
    public init(_ onFirstAppearAction: @escaping () -> ()) {
        self.onFirstAppearAction = onFirstAppearAction
    }
    
    public func body(content: Content) -> some View {
        content
            .onAppear {
                guard !hasAppeared else { return }
                hasAppeared = true
                onFirstAppearAction()
            }
    }
}

extension View {
    func onFirstAppear(_ onFirstAppearAction: @escaping () -> () ) -> some View {
        return modifier(OnFirstAppearModifier(onFirstAppearAction))
    }
}
