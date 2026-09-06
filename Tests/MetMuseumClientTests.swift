import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import TinyMetCore

final class MetMuseumClientTests: XCTestCase {
    private var session: URLSession!

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MuseumURLProtocol.self]
        session = URLSession(configuration: configuration)
    }

    override func tearDown() {
        session.invalidateAndCancel()
        MuseumURLProtocol.setHandler(nil)
        super.tearDown()
    }

    func testDepartmentSearchEncodesReservedCharactersAndUnicode() async throws {
        let query = "café & ink+paper?# 日本"
        MuseumURLProtocol.setHandler { request in
            let components = try XCTUnwrap(URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false))
            XCTAssertEqual(components.queryItems?.first { $0.name == "q" }?.value, query)
            XCTAssertEqual(components.queryItems?.first { $0.name == "departmentId" }?.value, "12")
            XCTAssertEqual(components.queryItems?.count, 2)
            XCTAssertNil(components.fragment)
            XCTAssertTrue(components.percentEncodedQuery?.contains("%2B") == true)
            return (200, Data(#"{"total":0,"objectIDs":null}"#.utf8))
        }
        let result = try await MetMuseumClient(session: session, cache: nil)
            .searchDepartmentForObjectsBySearchTerm(searchTerm: query, departmentId: 12)
        XCTAssertEqual(result.objectIDs, [])
    }

    func testAdvancedSearchUsesEncodedQueryItems() async throws {
        var query = SearchQuery(query: "oil & water")
        query.medium = "ink+paper"
        query.departmentId = 4
        MuseumURLProtocol.setHandler { request in
            let items = try XCTUnwrap(URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false)?.queryItems)
            XCTAssertEqual(items.first { $0.name == "q" }?.value, "oil & water")
            XCTAssertEqual(items.first { $0.name == "medium" }?.value, "ink+paper")
            XCTAssertEqual(items.first { $0.name == "departmentId" }?.value, "4")
            return (200, Data(#"{"total":0,"objectIDs":[]}"#.utf8))
        }
        let result = try await MetMuseumClient(session: session, cache: nil).searchObjects(query: query)
        XCTAssertTrue(result.objectIDs.isEmpty)
    }

    func testEveryEndpointRejectsHTTPErrorBeforeDecoding() async {
        MuseumURLProtocol.setHandler { _ in (503, Data("not JSON".utf8)) }
        let client = MetMuseumClient(session: session, cache: nil)
        let operations: [() async throws -> Void] = [
            { _ = try await client.fetchDepartments() },
            { _ = try await client.fetchObjects(departmentId: 1) },
            { _ = try await client.searchDepartmentForObjectsBySearchTerm(searchTerm: "art", departmentId: 1) },
            { _ = try await client.searchObjects(query: SearchQuery(query: "art")) },
            { _ = try await client.fetchObjectDetails(objectID: 1) }
        ]
        for operation in operations {
            do {
                try await operation()
                XCTFail("Expected HTTP error")
            } catch {
                XCTAssertEqual(error as? MetMuseumError, .httpStatus(503))
            }
        }
    }

    func testNullMissingAndEmptyIDsDecodeAsEmpty() throws {
        for json in [#"{"total":0,"objectIDs":null}"#, #"{"total":0,"objectIDs":[]}"#, #"{"total":0}"#] {
            let data = Data(json.utf8)
            XCTAssertEqual(try JSONDecoder().decode(SearchResult.self, from: data).objectIDs, [])
            XCTAssertEqual(try JSONDecoder().decode(ObjectIDs.self, from: data).objectIDs, [])
        }
    }

    func testEmptyBodyIsAnErrorRatherThanAnEmptyCollection() async {
        MuseumURLProtocol.setHandler { _ in (200, Data()) }
        do {
            _ = try await MetMuseumClient(session: session, cache: nil).fetchObjects(departmentId: 1)
            XCTFail("Expected a decoding error")
        } catch {
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testEmptyDepartmentResponse() async throws {
        MuseumURLProtocol.setHandler { _ in (200, Data(#"{"departments":[]}"#.utf8)) }
        let result = try await MetMuseumClient(session: session, cache: nil).fetchDepartments()
        XCTAssertTrue(result.departments.isEmpty)
    }

    func testObjectListKeepsAPIOrderAndDepartmentFilter() async throws {
        MuseumURLProtocol.setHandler { request in
            let components = try XCTUnwrap(URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false))
            XCTAssertEqual(components.path, "/public/collection/v1/objects")
            XCTAssertEqual(components.queryItems, [URLQueryItem(name: "departmentIds", value: "7")])
            return (200, Data(#"{"total":3,"objectIDs":[9,2,5]}"#.utf8))
        }
        let result = try await MetMuseumClient(session: session, cache: nil).fetchObjects(departmentId: 7)
        XCTAssertEqual(result.objectIDs, [9, 2, 5])
    }

    func testTransportErrorIsPropagated() async {
        MuseumURLProtocol.setHandler { _ in throw URLError(.notConnectedToInternet) }
        do {
            _ = try await MetMuseumClient(session: session, cache: nil).fetchDepartments()
            XCTFail("Expected transport error")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .notConnectedToInternet)
        }
    }

    func testNonHTTPResponseIsRejected() async {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [NonHTTPURLProtocol.self]
        let nonHTTPSession = URLSession(configuration: configuration)
        defer { nonHTTPSession.invalidateAndCancel() }
        do {
            _ = try await MetMuseumClient(session: nonHTTPSession, cache: nil).fetchDepartments()
            XCTFail("Expected invalid response error")
        } catch {
            XCTAssertEqual(error as? MetMuseumError, .invalidResponse)
        }
    }

    func testMalformedIDsAreNotSilentlyTreatedAsEmpty() {
        let data = Data(#"{"total":1,"objectIDs":"invalid"}"#.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(SearchResult.self, from: data))
        XCTAssertThrowsError(try JSONDecoder().decode(ObjectIDs.self, from: data))
    }

    func testPreviewClientProvidesOfflineConsistentFixtures() async throws {
        let client: any MetMuseumServing = PreviewMetMuseumClient()
        let departments = try await client.fetchDepartments()
        let department = try XCTUnwrap(departments.departments.first)
        let objects = try await client.fetchObjects(departmentId: department.departmentId)
        let objectID = try XCTUnwrap(objects.objectIDs.first)
        let artwork = try await client.fetchObjectDetails(objectID: objectID)
        let search = try await client.searchDepartmentForObjectsBySearchTerm(
            searchTerm: "CYPRESSES", departmentId: department.departmentId
        )
        XCTAssertEqual(objects.total, 1)
        XCTAssertEqual(artwork, PreviewMetMuseumClient.artwork)
        XCTAssertEqual(search.objectIDs, objects.objectIDs)
        XCTAssertEqual(search.total, objects.total)
        XCTAssertTrue(artwork.primaryImage.isEmpty)
        XCTAssertTrue(artwork.primaryImageSmall.isEmpty)
        let empty = try await client.searchDepartmentForObjectsBySearchTerm(
            searchTerm: "no matching preview artwork", departmentId: department.departmentId
        )
        XCTAssertEqual(empty.objectIDs, [])
        let unknownDepartment = try await client.fetchObjects(departmentId: -1)
        XCTAssertEqual(unknownDepartment.objectIDs, [])
        do {
            _ = try await client.fetchObjectDetails(objectID: -1)
            XCTFail("Unknown preview IDs should not return unrelated artwork")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .resourceUnavailable)
        }
    }
}

private final class NonHTTPURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let response = URLResponse(url: request.url!, mimeType: "application/json", expectedContentLength: 18, textEncodingName: nil)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(#"{"departments":[]}"#.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private final class MuseumURLProtocol: URLProtocol {
    private static let lock = NSLock()
    private static var handler: ((URLRequest) throws -> (Int, Data))?

    static func setHandler(_ newHandler: ((URLRequest) throws -> (Int, Data))?) {
        lock.lock()
        defer { lock.unlock() }
        handler = newHandler
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lock.lock()
        let handler = Self.handler
        Self.lock.unlock()
        do {
            let (status, data) = try XCTUnwrap(handler)(request)
            let response = try XCTUnwrap(HTTPURLResponse(
                url: try XCTUnwrap(request.url), statusCode: status, httpVersion: nil, headerFields: nil
            ))
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
