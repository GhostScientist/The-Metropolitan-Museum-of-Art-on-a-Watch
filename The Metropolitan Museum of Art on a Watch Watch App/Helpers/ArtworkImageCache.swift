import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

actor ArtworkImageCache {
    static let shared = ArtworkImageCache()

    enum CacheError: LocalizedError {
        case invalidURL, invalidResponse, tooLarge, invalidImage

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "This artwork has no valid image address."
            case .invalidResponse: return "The image server could not provide this image."
            case .tooLarge: return "This image is too large to load on your watch."
            case .invalidImage: return "This artwork image could not be opened."
            }
        }
    }

    private struct Entry: Codable {
        let url: String
        let data: Data
    }

    private let directory: URL
    private let maxBytes: Int
    private let maxImageBytes: Int
    private let session: URLSession

    init(directory: URL = CacheStorage.directory(named: "Images"),
         maxBytes: Int = 30 * 1_024 * 1_024, maxImageBytes: Int = 12 * 1_024 * 1_024,
         session: URLSession = ArtworkImageCache.makeSession()) {
        self.directory = directory
        self.maxBytes = max(0, maxBytes)
        self.maxImageBytes = max(0, maxImageBytes)
        self.session = session
        try? CacheStorage.prepare(directory)
        try? CacheStorage.trim(directory, maxEntries: 200, maxBytes: self.maxBytes)
    }

    nonisolated static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        return URLSession(configuration: configuration)
    }

    nonisolated static func imageURL(_ value: String) -> URL? {
        guard let url = URL(string: value),
              url.scheme?.lowercased() == "https",
              url.host != nil else { return nil }
        return url
    }

    func cachedData(for url: URL) -> Data? {
        let file = fileURL(for: url)
        guard let bytes = try? Data(contentsOf: file),
              let entry = try? PropertyListDecoder().decode(Entry.self, from: bytes),
              entry.url == url.absoluteString, !entry.data.isEmpty,
              entry.data.count <= maxImageBytes else {
            try? FileManager.default.removeItem(at: file)
            return nil
        }
        try? FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: file.path)
        return entry.data
    }

    func data(for url: URL) async throws -> Data {
        try Task.checkCancellation()
        guard Self.imageURL(url.absoluteString) != nil else { throw CacheError.invalidURL }
        if let data = cachedData(for: url) { return data }
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let data = try await download(request)
        guard !data.isEmpty else { throw CacheError.invalidImage }
        try Task.checkCancellation()
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        let entry = try encoder.encode(Entry(url: url.absoluteString, data: data))
        if entry.count <= maxBytes {
            do {
                try CacheStorage.prepare(directory)
                try entry.write(to: fileURL(for: url), options: .atomic)
                try CacheStorage.trim(directory, maxEntries: 200, maxBytes: maxBytes)
            } catch {
                // Images remain usable online even if the disposable disk cache cannot be written.
            }
        }
        return data
    }

    func remove(for url: URL) {
        try? FileManager.default.removeItem(at: fileURL(for: url))
    }

    private func download(_ request: URLRequest) async throws -> Data {
        #if canImport(Darwin)
        let (bytes, response) = try await session.bytes(for: request, delegate: HTTPSImageRedirectDelegate())
        defer { bytes.task.cancel() }
        try validate(response)
        var data = Data()
        for try await byte in bytes {
            try Task.checkCancellation()
            guard data.count < maxImageBytes else { throw CacheError.tooLarge }
            data.append(byte)
        }
        return data
        #else
        // FoundationNetworking does not yet expose URLSession.AsyncBytes.
        let (data, response) = try await session.data(for: request, delegate: HTTPSImageRedirectDelegate())
        try Task.checkCancellation()
        try validate(response)
        guard data.count <= maxImageBytes else { throw CacheError.tooLarge }
        return data
        #endif
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse,
              http.url?.scheme?.lowercased() == "https",
              (200...299).contains(http.statusCode),
              http.mimeType?.lowercased().hasPrefix("image/") == true else {
            throw CacheError.invalidResponse
        }

        guard response.expectedContentLength <= Int64(maxImageBytes) else { throw CacheError.tooLarge }
    }

    private func fileURL(for url: URL) -> URL {
        // The stored URL is also checked on read, so a hash collision cannot return another image.
        let hash = url.absoluteString.utf8.reduce(UInt64(14_695_981_039_346_656_037)) {
            ($0 ^ UInt64($1)) &* 1_099_511_628_211
        }
        return directory.appendingPathComponent(String(hash, radix: 16) + ".cache")
    }

}

private final class HTTPSImageRedirectDelegate: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(request.url?.scheme?.lowercased() == "https" ? request : nil)
    }
}
