//
//  DepartmentListView.swift
//  The Tiny Met Watch App
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
        objects = []
        currentIndex = 0
        allObjectIDs = []
        isLoading = true
        isSearching = true

        Task {
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

            allObjectIDs = searchResult.objectIDs
            isLoading = false

            await loadMoreContent()
        } catch {
            errorMessage = "Failed to search"
            isLoading = false
            isSearching = false
        }
    }

    private func loadMoreContent() async {
        guard !isLoading, currentIndex < allObjectIDs.count else { return }
        isLoading = true

        let endIndex = min(currentIndex + pageSize, allObjectIDs.count)
        let idsToFetch = Array(allObjectIDs[currentIndex..<endIndex])

        do {
            let newObjects = try await withThrowingTaskGroup(of: ObjectDetails.self) { group in
                for id in idsToFetch {
                    group.addTask {
                        if let cachedObject = await ObjectCache.shared.object(for: id) {
                            return cachedObject
                        }
                        let fetchedObject = try await metMuseumClient.fetchObjectDetails(objectID: id)
                        await ObjectCache.shared.cache(fetchedObject)
                        return fetchedObject
                    }
                }

                var fetchedObjects: [ObjectDetails] = []
                for try await object in group {
                    fetchedObjects.append(object)
                }
                return fetchedObjects.sorted { $0.objectID < $1.objectID }
            }

            objects.append(contentsOf: newObjects)
            currentIndex = endIndex
            isLoading = false
        } catch {
            if error.isInternetConnectionError {
                errorMessage = "No network connection - try again when reconnected."
            } else {
                errorMessage = "Failed to fetch objects"
            }
            isLoading = false
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
