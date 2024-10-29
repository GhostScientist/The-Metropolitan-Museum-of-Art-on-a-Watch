//
//  DepartmentListView.swift
//  The Metropolitan Museum of Art on a Watch Watch App
//
//  Created by Dakota Kim on 4/2/24.
//

import SwiftUI

struct DepartmentListView: View {
    @State private var objects: [ObjectDetails] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var allObjectIDs: [Int] = []
    @State private var currentIndex = 0
    private let pageSize = 10
    
    private let metMuseumClient = MetMuseumClient()
    
    var department: Department
    
    var body: some View {
        Group {
            if isLoading && objects.isEmpty {
                Text("Loading")
            } else if isSearching && objects.isEmpty {
                Text("No results found")
            } else {
                List(objects) { object in
                    NavigationLink(destination: ObjectDetailView(objectDetails: object)) {
                        Text(object.title)
                    }
                    .onAppear {
                        if objects.count > 0 && object == objects.last && currentIndex < allObjectIDs.count {
                                Task {
                                    await loadMoreContent()
                                }
                            }
                        }
                }
                .navigationTitle(department.displayName)
                
                if isLoading && !objects.isEmpty {
                    ProgressView()
                        .padding()
                }
            }
        }
        .onFirstAppear {
            loadInitialContent()
        }
        .searchable(text: $searchText, prompt: "Search objects")
        .onSubmit(of: .search) {
            resetAndSearch()
        }
    }
    
    private func resetAndSearch() {
        Task {
            await MainActor.run {
                objects = []
                currentIndex = 0
                allObjectIDs = []
                isLoading = true
                isSearching = true
            }
            await searchObjects()
        }
    }

    private func searchObjects() async {
        guard !searchText.isEmpty else {
            loadInitialContent()
            return
        }
        
        do {
            let searchResult = try await metMuseumClient.searchDepartmentForObjectsBySearchTerm(
                searchTerm: searchText,
                departmentId: department.departmentId
            )
            
            await MainActor.run {
                allObjectIDs = searchResult.objectIDs
                isLoading = false
            }
            
            await loadMoreContent()
        } catch {
            await MainActor.run {
                errorMessage = "Failed to search"
                isLoading = false
                isSearching = false
            }
        }
    }

    private func loadMoreContent() async {
        print("Loading more content from index \(currentIndex)")
        
        await MainActor.run {
            guard !isLoading, currentIndex < allObjectIDs.count else {
                print("Guard condition failed - isLoading: \(isLoading), currentIndex: \(currentIndex), total IDs: \(allObjectIDs.count)")
                return
            }
            isLoading = true
        }
        
        let endIndex = await MainActor.run {
            let end = min(currentIndex + pageSize, allObjectIDs.count)
            let ids = Array(allObjectIDs[currentIndex..<end])
            print("Preparing to fetch IDs: \(ids)")
            return end
        }
        
        let idsToFetch = await MainActor.run {
            Array(allObjectIDs[currentIndex..<endIndex])
        }
        
        do {
            let newObjects = try await withThrowingTaskGroup(of: ObjectDetails.self) { group in
                for id in idsToFetch {
                    group.addTask {
                        if let cachedObject = await ObjectCache.shared.object(for: id) {
                            print("✅ Cache hit for object \(id)")
                            return cachedObject
                        }
                        print("❌ Cache miss for object \(id), fetching from network...")
                        let fetchedObject = try await metMuseumClient.fetchObjectDetails(objectID: id)
                        print("📥 Successfully fetched object \(id) from network")
                        await ObjectCache.shared.cache(fetchedObject)
                        print("💾 Cached object \(id)")
                        return fetchedObject
                    }
                }
                
                var fetchedObjects: [ObjectDetails] = []
                for try await object in group {
                    print("📦 Received object: \(object.objectID)")
                    fetchedObjects.append(object)
                }
                print("🔄 Sorting \(fetchedObjects.count) objects")
                return fetchedObjects.sorted { $0.objectID < $1.objectID }
            }
            
            await MainActor.run {
                objects.append(contentsOf: newObjects)
                print("✨ Added \(newObjects.count) new objects, total now: \(objects.count)")
                currentIndex = endIndex
                isLoading = false
            }
        } catch {
            await MainActor.run {
                print("❌ Error occurred: \(error)")
                if error.isInternetConnectionError {
                    errorMessage = "No network connection - try again when reconnected."
                } else {
                    errorMessage = "Failed to fetch objects"
                }
                isLoading = false
            }
        }
    }
    
    private func loadInitialContent() {
        Task {
            do {
                if isSearching && searchText != "" {
                    let searchResult = try await metMuseumClient.searchDepartmentForObjectsBySearchTerm(searchTerm: searchText, departmentId: department.departmentId)
                    allObjectIDs = searchResult.objectIDs
                } else {
                    let result = try await metMuseumClient.fetchObjects(departmentId: department.departmentId)
                    allObjectIDs = Array(result.allAsInt)
                }
                await loadMoreContent()
            } catch {
                errorMessage = "Failed to load initial content"
            }
        }
    }
}

#Preview {
    DepartmentListView(department: Department(departmentId: 1, displayName: "American Decorative Arts"))
}
