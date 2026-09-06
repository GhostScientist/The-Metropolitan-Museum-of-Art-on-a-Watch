import Foundation
import XCTest
@testable import TinyMetCore

@MainActor
final class DepartmentBrowserTests: XCTestCase {
    func testDuplicateLoadsAreGuardedAndAPIRankingIsPreserved() async throws {
        let client = ControlledMuseum(ids: [9, 2, 9, 7, 2, 4], heldDetails: [9, 2])
        let browser = DepartmentBrowser(departmentID: 1, client: client, pageSize: 2)
        let first = try XCTUnwrap(browser.loadIfNeeded())
        XCTAssertTrue(browser.isLoading)
        XCTAssertNil(browser.loadIfNeeded())
        XCTAssertNil(browser.loadMore())
        await client.waitForDetail(9)
        await client.waitForDetail(2)
        await client.completeDetail(2)
        await client.completeDetail(9)
        await first.value
        XCTAssertEqual(browser.objects.map(\.objectID), [9, 2])
        let next = try XCTUnwrap(browser.loadMore())
        XCTAssertNil(browser.loadMore())
        await next.value
        XCTAssertEqual(browser.objects.map(\.objectID), [9, 2, 7, 4])
        XCTAssertFalse(browser.hasMore)
        XCTAssertNil(browser.loadMore())
        let calls = await client.detailCalls
        XCTAssertEqual(calls.sorted(), [2, 4, 7, 9])
        let listCalls = await client.listCalls
        XCTAssertEqual(listCalls, 1)
    }

    func testInitialFailureCanRetry() async throws {
        let client = ControlledMuseum(ids: [5], listFailures: 1)
        let browser = DepartmentBrowser(departmentID: 1, client: client)
        await browser.loadIfNeeded()?.value
        XCTAssertFalse(browser.isLoading)
        XCTAssertNotNil(browser.errorMessage)
        XCTAssertFalse(browser.hasLoaded)
        try await XCTUnwrap(browser.retry()).value
        XCTAssertNil(browser.errorMessage)
        XCTAssertEqual(browser.objects.map(\.objectID), [5])
        XCTAssertTrue(browser.hasLoaded)
    }

    func testFailedPageKeepsExistingObjectsAndRetriesSameIDs() async throws {
        let client = ControlledMuseum(ids: [5, 8], detailFailures: [8: 1])
        let browser = DepartmentBrowser(departmentID: 1, client: client, pageSize: 1)
        await browser.loadIfNeeded()?.value
        await browser.loadMore()?.value
        XCTAssertEqual(browser.objects.map(\.objectID), [5])
        XCTAssertNotNil(browser.errorMessage)
        XCTAssertFalse(browser.isLoading)
        XCTAssertNil(browser.loadMore())
        try await XCTUnwrap(browser.retry()).value
        XCTAssertNil(browser.errorMessage)
        XCTAssertEqual(browser.objects.map(\.objectID), [5, 8])
        let calls = await client.detailCalls
        XCTAssertEqual(calls, [5, 8, 8])
    }

    func testObsoleteSearchSuccessIsCancelledAndCannotReplaceNewResults() async {
        let client = ControlledMuseum(ids: [], heldSearches: ["old", "new"])
        let browser = DepartmentBrowser(departmentID: 1, client: client)
        let old = browser.search("old")
        await client.waitForSearch("old")
        let new = browser.search("new")
        await client.waitForSearch("new")
        await client.completeSearch("new", result: .success([8, 3]))
        await new.value
        await client.completeSearch("old", result: .success([99]))
        await old.value
        XCTAssertEqual(browser.objects.map(\.objectID), [8, 3])
        XCTAssertNil(browser.errorMessage)
        XCTAssertFalse(browser.isLoading)
        let cancelled = await client.cancelledSearches
        XCTAssertTrue(cancelled.contains("old"))
    }

    func testSearchReplacedBeforeTaskStartsDoesNotReachClient() async {
        let client = ControlledMuseum(ids: [], searches: ["old": [99], "new": [3]])
        let browser = DepartmentBrowser(departmentID: 1, client: client)
        let old = browser.search("old")
        let new = browser.search("new")
        await old.value
        await new.value
        let calls = await client.searchCalls
        XCTAssertEqual(calls, ["new"])
        XCTAssertEqual(browser.objects.map(\.objectID), [3])
        XCTAssertNil(browser.errorMessage)
    }

    func testFailedBatchDoesNotAppendPartialResultsOrSkipIDsOnRetry() async throws {
        let client = ControlledMuseum(ids: [9, 5, 3], detailFailures: [5: 1])
        let browser = DepartmentBrowser(departmentID: 1, client: client, pageSize: 3)
        await browser.loadIfNeeded()?.value
        XCTAssertTrue(browser.objects.isEmpty)
        XCTAssertNotNil(browser.errorMessage)
        try await XCTUnwrap(browser.retry()).value
        XCTAssertEqual(browser.objects.map(\.objectID), [9, 5, 3])
        XCTAssertFalse(browser.hasMore)
        XCTAssertNil(browser.errorMessage)
    }

    func testObsoleteFailureDoesNotClearNewLoadingOrSetError() async {
        let client = ControlledMuseum(ids: [], heldSearches: ["old", "new"])
        let browser = DepartmentBrowser(departmentID: 1, client: client)
        let old = browser.search("old")
        await client.waitForSearch("old")
        let new = browser.search("new")
        await client.waitForSearch("new")
        await client.completeSearch("old", result: .failure(URLError(.timedOut)))
        await old.value
        XCTAssertTrue(browser.isLoading)
        XCTAssertNil(browser.errorMessage)
        await client.completeSearch("new", result: .success([6]))
        await new.value
        XCTAssertEqual(browser.objects.map(\.objectID), [6])
        XCTAssertNil(browser.errorMessage)
    }

    func testObsoletePageFailureCannotDamageNewSearch() async {
        let client = ControlledMuseum(ids: [1], searches: ["new": [7]], heldDetails: [1])
        let browser = DepartmentBrowser(departmentID: 1, client: client)
        let initial = browser.loadIfNeeded()
        await client.waitForDetail(1)
        await browser.search("new").value
        await client.completeDetail(1, error: URLError(.timedOut))
        await initial?.value
        XCTAssertEqual(browser.objects.map(\.objectID), [7])
        XCTAssertNil(browser.errorMessage)
        XCTAssertFalse(browser.isLoading)
    }

    func testClearingSearchRestoresBrowsingAndIgnoresPendingSearch() async {
        let client = ControlledMuseum(ids: [3, 1], heldSearches: ["art"])
        let browser = DepartmentBrowser(departmentID: 1, client: client)
        let search = browser.search("art")
        await client.waitForSearch("art")
        await browser.search("  \n").value
        XCTAssertFalse(browser.isSearching)
        XCTAssertEqual(browser.objects.map(\.objectID), [3, 1])
        await client.completeSearch("art", result: .success([99]))
        await search.value
        XCTAssertEqual(browser.objects.map(\.objectID), [3, 1])
    }

    func testEmptySearchResultsAndEmptyDepartmentAreNotErrors() async {
        let client = ControlledMuseum(ids: [])
        let browser = DepartmentBrowser(departmentID: 1, client: client)
        await browser.loadIfNeeded()?.value
        XCTAssertTrue(browser.hasLoaded)
        XCTAssertFalse(browser.isSearching)
        XCTAssertNil(browser.errorMessage)
        await browser.search("nothing").value
        XCTAssertTrue(browser.hasLoaded)
        XCTAssertTrue(browser.isSearching)
        XCTAssertTrue(browser.objects.isEmpty)
        XCTAssertFalse(browser.hasMore)
        XCTAssertFalse(browser.isLoading)
        XCTAssertNil(browser.errorMessage)
    }

    func testSearchFailureRetriesCurrentSearchNotDepartment() async throws {
        let client = ControlledMuseum(ids: [99], heldSearches: ["art"])
        let browser = DepartmentBrowser(departmentID: 1, client: client)
        let search = browser.search("art")
        await client.waitForSearch("art")
        await client.completeSearch("art", result: .failure(URLError(.notConnectedToInternet)))
        await search.value
        XCTAssertNotNil(browser.errorMessage)
        let retry = try XCTUnwrap(browser.retry())
        await client.waitForSearch("art")
        await client.completeSearch("art", result: .success([4]))
        await retry.value
        XCTAssertNil(browser.errorMessage)
        XCTAssertEqual(browser.objects.map(\.objectID), [4])
        let listCalls = await client.listCalls
        XCTAssertEqual(listCalls, 0)
    }
}

private actor ControlledMuseum: MetMuseumServing {
    private let ids: [Int]
    private let searches: [String: [Int]]
    private let heldSearches: Set<String>
    private let heldDetails: Set<Int>
    private var listFailures: Int
    private var detailFailures: [Int: Int]
    private var searchContinuations: [String: CheckedContinuation<Result<[Int], Error>, Never>] = [:]
    private var detailContinuations: [Int: CheckedContinuation<ObjectDetails, Error>] = [:]
    private var searchWaiters: [String: CheckedContinuation<Void, Never>] = [:]
    private var detailWaiters: [Int: CheckedContinuation<Void, Never>] = [:]
    private(set) var detailCalls: [Int] = []
    private(set) var listCalls = 0
    private(set) var searchCalls: [String] = []
    private(set) var cancelledSearches: Set<String> = []

    init(ids: [Int], searches: [String: [Int]] = [:], heldSearches: Set<String> = [],
         heldDetails: Set<Int> = [], listFailures: Int = 0, detailFailures: [Int: Int] = [:]) {
        self.ids = ids
        self.searches = searches
        self.heldSearches = heldSearches
        self.heldDetails = heldDetails
        self.listFailures = listFailures
        self.detailFailures = detailFailures
    }

    func fetchDepartments() async throws -> DepartmentResponse { DepartmentResponse(departments: []) }

    func fetchObjects(departmentId: Int) async throws -> ObjectIDs {
        listCalls += 1
        if listFailures > 0 {
            listFailures -= 1
            throw URLError(.notConnectedToInternet)
        }
        return ObjectIDs(total: ids.count, objectIDs: ids)
    }

    func searchDepartmentForObjectsBySearchTerm(searchTerm: String, departmentId: Int) async throws -> SearchResult {
        searchCalls.append(searchTerm)
        let result: [Int]
        if heldSearches.contains(searchTerm) {
            let response = await withCheckedContinuation { continuation in
                searchContinuations[searchTerm] = continuation
                searchWaiters.removeValue(forKey: searchTerm)?.resume()
            }
            if Task.isCancelled { cancelledSearches.insert(searchTerm) }
            result = try response.get()
        } else {
            result = searches[searchTerm] ?? []
        }
        return SearchResult(total: result.count, objectIDs: result)
    }

    func fetchObjectDetails(objectID: Int) async throws -> ObjectDetails {
        detailCalls.append(objectID)
        if detailFailures[objectID, default: 0] > 0 {
            detailFailures[objectID, default: 0] -= 1
            throw URLError(.timedOut)
        }
        if heldDetails.contains(objectID) {
            return try await withCheckedThrowingContinuation { continuation in
                detailContinuations[objectID] = continuation
                detailWaiters.removeValue(forKey: objectID)?.resume()
            }
        }
        return makeObject(objectID)
    }

    func waitForSearch(_ query: String) async {
        if searchContinuations[query] != nil { return }
        await withCheckedContinuation { searchWaiters[query] = $0 }
    }

    func waitForDetail(_ id: Int) async {
        if detailContinuations[id] != nil { return }
        await withCheckedContinuation { detailWaiters[id] = $0 }
    }

    func completeSearch(_ query: String, result: Result<[Int], Error>) {
        searchContinuations.removeValue(forKey: query)?.resume(returning: result)
    }

    func completeDetail(_ id: Int, error: Error? = nil) {
        let continuation = detailContinuations.removeValue(forKey: id)
        if let error {
            continuation?.resume(throwing: error)
        } else {
            continuation?.resume(returning: makeObject(id))
        }
    }
}

private func makeObject(_ id: Int) -> ObjectDetails {
    ObjectDetails(
        objectID: id, isHighlight: false, accessionYear: "", isPublicDomain: true,
        primaryImage: "", primaryImageSmall: "", department: "", objectName: "", title: "Object \(id)",
        culture: "", period: "", artistDisplayName: "", artistDisplayBio: "", objectDate: "",
        medium: "", dimensions: "", creditLine: "", geographyType: "", city: "", country: "",
        classification: "", objectURL: ""
    )
}
