import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import TinyMetCore

@MainActor
final class OfflineStorageTests: XCTestCase {
    func testMetadataSurvivesNewCacheInstance() async throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let object = artwork(1)
        await ObjectCache(directory: directory).cache(object)
        let restored = await ObjectCache(directory: directory).object(for: 1)
        XCTAssertEqual(restored, object)
    }

    func testMetadataCountLimitEvictsOldestDiskEntry() async throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let cache = ObjectCache(directory: directory, maxEntries: 1)
        await cache.cache(artwork(1))
        try ageFiles(in: directory)
        await cache.cache(artwork(2))
        let restored = ObjectCache(directory: directory, maxEntries: 1)
        let old = await restored.object(for: 1)
        let current = await restored.object(for: 2)
        XCTAssertNil(old)
        XCTAssertEqual(current?.objectID, 2)
        XCTAssertEqual(try cacheFiles(in: directory).count, 1)
    }

    func testMetadataByteLimitAndOversizedEntry() async throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let bytes = try JSONEncoder().encode(artwork(1)).count
        let cache = ObjectCache(directory: directory, maxBytes: bytes + 10)
        await cache.cache(artwork(1))
        try ageFiles(in: directory)
        await cache.cache(artwork(2))
        XCTAssertLessThanOrEqual(try diskBytes(in: directory), bytes + 10)
        XCTAssertEqual(try cacheFiles(in: directory).count, 1)
        let tinyDirectory = directory.appendingPathComponent("tiny")
        await ObjectCache(directory: tinyDirectory, maxBytes: 1).cache(artwork(3))
        XCTAssertTrue(try cacheFiles(in: tinyDirectory).isEmpty)
    }

    func testCorruptAndMismatchedMetadataAreDiscarded() async throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try Data("broken".utf8).write(to: directory.appendingPathComponent("1.cache"))
        try JSONEncoder().encode(artwork(99)).write(to: directory.appendingPathComponent("2.cache"))
        let cache = ObjectCache(directory: directory)
        let corrupt = await cache.object(for: 1)
        let mismatched = await cache.object(for: 2)
        XCTAssertNil(corrupt)
        XCTAssertNil(mismatched)
        XCTAssertTrue(try cacheFiles(in: directory).isEmpty)
    }

    func testFavoritesPersistAndRemoveAcrossInstances() async throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("favorites.json")
        let store = FavoritesStore(fileURL: file)
        XCTAssertTrue(store.isLoaded)
        try store.save(artwork(1))
        try store.save(artwork(1))
        try store.save(artwork(2))
        let restored = FavoritesStore(fileURL: file)
        XCTAssertEqual(restored.favorites.map(\.objectID), [2, 1])
        try restored.remove(1)
        XCTAssertEqual(FavoritesStore(fileURL: file).favorites.map(\.objectID), [2])
    }

    func testFavoriteCapDoesNotChangePersistedState() async throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("favorites.json")
        let store = FavoritesStore(fileURL: file, limit: 1)
        try store.save(artwork(1))
        let saved = try Data(contentsOf: file)
        XCTAssertThrowsError(try store.save(artwork(2)))
        XCTAssertEqual(store.favorites.map(\.objectID), [1])
        XCTAssertEqual(try Data(contentsOf: file), saved)
        XCTAssertNotNil(store.errorMessage)
    }

    func testFavoriteWriteFailuresKeepVisibleAndPersistedState() async throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("favorites.json")
        let backup = directory.appendingPathComponent("saved.json")
        let store = FavoritesStore(fileURL: file)
        try store.save(artwork(1))
        try FileManager.default.moveItem(at: file, to: backup)
        try FileManager.default.createDirectory(at: file, withIntermediateDirectories: false)
        XCTAssertThrowsError(try store.save(artwork(2)))
        XCTAssertThrowsError(try store.remove(1))
        XCTAssertEqual(store.favorites.map(\.objectID), [1])
        XCTAssertNotNil(store.errorMessage)
        try FileManager.default.removeItem(at: file)
        try FileManager.default.moveItem(at: backup, to: file)
        XCTAssertEqual(FavoritesStore(fileURL: file).favorites.map(\.objectID), [1])
        try store.remove(1)
        XCTAssertTrue(store.favorites.isEmpty)
        XCTAssertNil(store.errorMessage)
    }

    func testCorruptFavoritesBlockMutationsUntilSuccessfulReload() async throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("favorites.json")
        let corrupt = Data("not valid JSON".utf8)
        try corrupt.write(to: file)
        let store = FavoritesStore(fileURL: file)
        XCTAssertFalse(store.isLoaded)
        XCTAssertThrowsError(try store.save(artwork(1)))
        XCTAssertThrowsError(try store.remove(1))
        XCTAssertEqual(try Data(contentsOf: file), corrupt)
        try JSONEncoder().encode([artwork(2)]).write(to: file, options: .atomic)
        store.reload()
        XCTAssertTrue(store.isLoaded)
        XCTAssertNil(store.errorMessage)
        XCTAssertEqual(store.favorites.map(\.objectID), [2])
    }

    func testImageCacheSurvivesRestartWithoutNetwork() async throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let online = imageSession()
        let offline = imageSession(offline: true)
        defer { online.invalidateAndCancel(); offline.invalidateAndCancel() }
        let url = try XCTUnwrap(URL(string: "https://example.test/1.png"))
        let first = try await ArtworkImageCache(directory: directory, session: online).data(for: url)
        let second = try await ArtworkImageCache(directory: directory, session: offline).data(for: url)
        XCTAssertEqual(first, second)
        XCTAssertEqual(first.count, 512)
    }

    func testImageDiskEvictionKeepsByteBound() async throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let session = imageSession()
        defer { session.invalidateAndCancel() }
        let cache = ArtworkImageCache(directory: directory, maxBytes: 750, session: session)
        let firstURL = try XCTUnwrap(URL(string: "https://example.test/1.png"))
        let secondURL = try XCTUnwrap(URL(string: "https://example.test/2.png"))
        _ = try await cache.data(for: firstURL)
        XCTAssertEqual(try cacheFiles(in: directory).count, 1)
        try ageFiles(in: directory)
        _ = try await cache.data(for: secondURL)
        let old = await cache.cachedData(for: firstURL)
        let current = await cache.cachedData(for: secondURL)
        XCTAssertNil(old)
        XCTAssertNotNil(current)
        XCTAssertLessThanOrEqual(try diskBytes(in: directory), 750)
    }

    func testImageHTTPAndMIMERejectionsAreNotCached() async throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let session = imageSession()
        defer { session.invalidateAndCancel() }
        let cache = ArtworkImageCache(directory: directory, session: session)
        for path in ["404", "html", "non-http", "insecure-response"] {
            let url = try XCTUnwrap(URL(string: "https://example.test/\(path)"))
            do {
                _ = try await cache.data(for: url)
                XCTFail("Expected response rejection for \(path)")
            } catch {
                guard case ArtworkImageCache.CacheError.invalidResponse = error else {
                    return XCTFail("Unexpected error: \(error)")
                }
            }
        }
        XCTAssertTrue(try cacheFiles(in: directory).isEmpty)
    }

    func testOversizedEmptyAndInvalidImageRequestsAreRejected() async throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let session = imageSession()
        defer { session.invalidateAndCancel() }
        let cache = ArtworkImageCache(directory: directory, maxImageBytes: 256, session: session)
        let oversized = try XCTUnwrap(URL(string: "https://example.test/oversize"))
        do {
            _ = try await cache.data(for: oversized)
            XCTFail("Expected size rejection")
        } catch {
            guard case ArtworkImageCache.CacheError.tooLarge = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
        let empty = try XCTUnwrap(URL(string: "https://example.test/empty"))
        do {
            _ = try await cache.data(for: empty)
            XCTFail("Expected empty image rejection")
        } catch {
            guard case ArtworkImageCache.CacheError.invalidImage = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
        XCTAssertNil(ArtworkImageCache.imageURL("file:///image.png"))
        XCTAssertNil(ArtworkImageCache.imageURL("http://example.test/image.png"))
        XCTAssertNil(ArtworkImageCache.imageURL("not a URL"))
        let insecure = try XCTUnwrap(URL(string: "http://example.test/image.png"))
        do {
            _ = try await cache.data(for: insecure)
            XCTFail("Expected HTTPS requirement")
        } catch {
            guard case ArtworkImageCache.CacheError.invalidURL = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
        XCTAssertTrue(try cacheFiles(in: directory).isEmpty)
    }

    func testCancelledImageRequestIsNotCached() async throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let session = imageSession()
        defer { session.invalidateAndCancel() }
        let cache = ArtworkImageCache(directory: directory, session: session)
        let url = try XCTUnwrap(URL(string: "https://example.test/1.png"))
        let task = Task { try await cache.data(for: url) }
        task.cancel()
        do {
            _ = try await task.value
            XCTFail("Expected cancellation")
        } catch {
            XCTAssertTrue(error is CancellationError || (error as? URLError)?.code == .cancelled)
        }
        XCTAssertTrue(try cacheFiles(in: directory).isEmpty)
    }

    func testFavoritePreviewUsesSmallImageAndFailureKeepsMetadata() async throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = FavoritesStore(fileURL: directory.appendingPathComponent("favorites.json"))
        let object = artwork(1, small: "https://example.test/1.png", full: "https://example.test/404")
        try store.save(object)
        let online = imageSession()
        let offline = imageSession(offline: true)
        defer { online.invalidateAndCancel(); offline.invalidateAndCancel() }
        let cache = ArtworkImageCache(directory: directory.appendingPathComponent("images"), session: online)
        let cached = await store.cachePreview(for: object, cache: cache)
        XCTAssertTrue(cached)
        let missing = ArtworkImageCache(directory: directory.appendingPathComponent("missing"), session: offline)
        let failed = await store.cachePreview(for: object, cache: missing)
        XCTAssertFalse(failed)
        XCTAssertTrue(store.contains(1))
        XCTAssertTrue(FavoritesStore(fileURL: directory.appendingPathComponent("favorites.json")).contains(1))
    }

    private func makeDirectory() throws -> URL {
        let directory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(".build/OfflineStorageTests/\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func cacheFiles(in directory: URL) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "cache" }
    }

    private func diskBytes(in directory: URL) throws -> Int {
        try cacheFiles(in: directory).reduce(0) { try $0 + Data(contentsOf: $1).count }
    }

    private func ageFiles(in directory: URL) throws {
        for file in try cacheFiles(in: directory) {
            try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 1)],
                                                 ofItemAtPath: file.path)
        }
    }

    private func imageSession(offline: Bool = false) -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = offline ? [OfflineImageProtocol.self] : [ImageFixtureProtocol.self]
        return URLSession(configuration: configuration)
    }

    private func artwork(_ id: Int, small: String = "", full: String = "") -> ObjectDetails {
        ObjectDetails(
            objectID: id, isHighlight: false, accessionYear: "", isPublicDomain: true,
            primaryImage: full, primaryImageSmall: small, department: "", objectName: "", title: "Object \(id)",
            culture: "", period: "", artistDisplayName: "", artistDisplayBio: "", objectDate: "",
            medium: "", dimensions: "", creditLine: "", geographyType: "", city: "", country: "",
            classification: "", objectURL: ""
        )
    }
}

private final class ImageFixtureProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url else { return }
        let path = url.lastPathComponent
        let body = path == "empty" ? Data() : Data(repeating: 42, count: 512)
        let response: URLResponse
        if path == "non-http" {
            response = URLResponse(url: url, mimeType: "image/png", expectedContentLength: 512, textEncodingName: nil)
        } else {
            let responseURL = path == "insecure-response" ? URL(string: "http://example.test/image.png")! : url
            response = HTTPURLResponse(url: responseURL, statusCode: path == "404" ? 404 : 200,
                                       httpVersion: nil,
                                       headerFields: ["Content-Type": path == "html" ? "text/html" : "image/png"])!
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private final class OfflineImageProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
    }
    override func stopLoading() {}
}
