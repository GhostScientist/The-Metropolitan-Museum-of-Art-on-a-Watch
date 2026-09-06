import Foundation
import Observation

@Observable
@MainActor
final class DepartmentBrowser {
    private(set) var objects: [ObjectDetails] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var isSearching = false
    private(set) var hasLoaded = false

    @ObservationIgnored private let client: any MetMuseumServing
    @ObservationIgnored private let departmentID: Int
    @ObservationIgnored private let pageSize: Int
    @ObservationIgnored private var objectIDs: [Int] = []
    @ObservationIgnored private var currentIndex = 0
    @ObservationIgnored private var query = ""
    @ObservationIgnored private var needsIDs = true
    @ObservationIgnored private var generation = 0
    @ObservationIgnored private var started = false
    @ObservationIgnored private var task: Task<Void, Never>?

    var hasMore: Bool { currentIndex < objectIDs.count }

    init(departmentID: Int, client: any MetMuseumServing = MetMuseumClient(), pageSize: Int = 10) {
        self.departmentID = departmentID
        self.client = client
        self.pageSize = max(1, pageSize)
    }

    @discardableResult
    func loadIfNeeded() -> Task<Void, Never>? {
        guard !started else { return nil }
        return search("")
    }

    @discardableResult
    func search(_ searchTerm: String) -> Task<Void, Never> {
        task?.cancel()
        generation += 1
        started = true
        query = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        isSearching = !query.isEmpty
        objects = []
        objectIDs = []
        currentIndex = 0
        needsIDs = true
        hasLoaded = false
        return startLoading()
    }

    @discardableResult
    func loadMore() -> Task<Void, Never>? {
        // Check and reserve the page synchronously on the actor, before creating a task.
        guard !isLoading, errorMessage == nil, !needsIDs, hasMore else { return nil }
        return startLoading()
    }

    @discardableResult
    func retry() -> Task<Void, Never>? {
        guard !isLoading, errorMessage != nil else { return nil }
        return startLoading()
    }

    private func startLoading() -> Task<Void, Never> {
        isLoading = true
        errorMessage = nil
        let requestGeneration = generation
        let requestQuery = query
        let task = Task { [weak self] in
            guard let self else { return }
            do {
                try Task.checkCancellation()
                guard generation == requestGeneration else { return }
                if needsIDs {
                    let ids: [Int]
                    if requestQuery.isEmpty {
                        ids = try await client.fetchObjects(departmentId: departmentID).objectIDs
                    } else {
                        ids = try await client.searchDepartmentForObjectsBySearchTerm(
                            searchTerm: requestQuery, departmentId: departmentID
                        ).objectIDs
                    }
                    try Task.checkCancellation()
                    guard generation == requestGeneration else { return }
                    var seen = Set<Int>()
                    objectIDs = ids.filter { seen.insert($0).inserted }
                    needsIDs = false
                }

                let endIndex = min(currentIndex + pageSize, objectIDs.count)
                let ids = Array(objectIDs[currentIndex..<endIndex])
                let service = client
                let fetched = try await withThrowingTaskGroup(of: (Int, ObjectDetails).self) { group in
                    for (index, id) in ids.enumerated() {
                        group.addTask {
                            try Task.checkCancellation()
                            return (index, try await service.fetchObjectDetails(objectID: id))
                        }
                    }
                    var results: [Int: ObjectDetails] = [:]
                    for try await (index, object) in group {
                        results[index] = object
                    }
                    return ids.indices.compactMap { results[$0] }
                }
                try Task.checkCancellation()
                guard generation == requestGeneration else { return }
                var seen = Set(objects.map(\.objectID))
                objects.append(contentsOf: fetched.filter { seen.insert($0.objectID).inserted })
                currentIndex = endIndex
                hasLoaded = true
                isLoading = false
            } catch {
                // A cancelled request may still fail after its replacement has started.
                guard generation == requestGeneration else { return }
                errorMessage = "Unable to load objects. \(error.localizedDescription)"
                isLoading = false
            }
        }
        self.task = task
        return task
    }
}
