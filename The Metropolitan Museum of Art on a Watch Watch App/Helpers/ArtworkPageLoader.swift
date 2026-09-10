//
//  ArtworkPageLoader.swift
//  The Tiny Met
//

import Observation
import SwiftUI

/// Turns a list of object IDs into pages of `ObjectDetails`, ten at a time,
/// preserving the order the API returned them in (relevance, for searches).
/// Shared by the department gallery and search results.
@MainActor
@Observable
final class ArtworkPageLoader {
    private(set) var objects: [ObjectDetails] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var totalCount = 0

    private var objectIDs: [Int] = []
    private var nextIndex = 0
    private let pageSize = 10
    private let client = MetMuseumClient()

    var hasMore: Bool { nextIndex < objectIDs.count }

    func replace(with ids: [Int]) async {
        objects = []
        objectIDs = ids
        nextIndex = 0
        totalCount = ids.count
        errorMessage = nil
        await loadNextPage()
    }

    func loadMoreIfNeeded(after object: ObjectDetails) {
        guard object.id == objects.last?.id, hasMore, !isLoading else { return }
        Task { await loadNextPage() }
    }

    func loadNextPage() async {
        guard !isLoading, hasMore else { return }
        isLoading = true
        errorMessage = nil

        let end = min(nextIndex + pageSize, objectIDs.count)
        let ids = Array(objectIDs[nextIndex..<end])

        let page = await withTaskGroup(of: ObjectDetails?.self) { group in
            for id in ids {
                group.addTask { [client] in
                    if let cached = await ObjectCache.shared.object(for: id) {
                        return cached
                    }
                    // The Met's ID lists occasionally contain objects that 404.
                    // Skip those rather than failing the whole page.
                    guard let fetched = try? await client.fetchObjectDetails(objectID: id) else {
                        return nil
                    }
                    await ObjectCache.shared.cache(fetched)
                    return fetched
                }
            }
            var results: [ObjectDetails] = []
            for await item in group {
                if let item { results.append(item) }
            }
            return results
        }

        if page.isEmpty {
            errorMessage = "Couldn't reach the collection. Check your connection and try again."
        } else {
            let order = Dictionary(uniqueKeysWithValues: ids.enumerated().map { ($1, $0) })
            objects.append(contentsOf: page.sorted { (order[$0.id] ?? 0) < (order[$1.id] ?? 0) })
        }
        nextIndex = end
        isLoading = false
    }
}
