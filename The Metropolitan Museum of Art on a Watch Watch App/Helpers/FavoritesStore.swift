import Foundation
import Observation

@Observable
@MainActor
final class FavoritesStore {
    static let shared = FavoritesStore()
    private(set) var favorites: [ObjectDetails] = []
    private(set) var errorMessage: String?
    private(set) var isLoaded = false
    let limit: Int
    @ObservationIgnored private let fileURL: URL

    enum StoreError: LocalizedError {
        case limitReached(Int), unreadable
        var errorDescription: String? {
            switch self {
            case .limitReached(let limit): return "You can save up to \(limit) favorites. Remove one first."
            case .unreadable: return "Saved favorites could not be read. Retry before making changes."
            }
        }
    }

    init(fileURL: URL = FavoritesStore.defaultFileURL, limit: Int = 100) {
        self.fileURL = fileURL
        self.limit = max(0, limit)
        reload()
    }

    nonisolated static var defaultFileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")
        return base.appendingPathComponent("TheTinyMet", isDirectory: true)
            .appendingPathComponent("favorites.json")
    }

    func contains(_ id: Int) -> Bool {
        favorites.contains { $0.objectID == id }
    }

    func reload() {
        do {
            let data: Data
            do {
                data = try Data(contentsOf: fileURL)
            } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
                favorites = []
                isLoaded = true
                errorMessage = nil
                return
            }
            let decoded = try JSONDecoder().decode([ObjectDetails].self, from: data)
            var seen = Set<Int>()
            favorites = decoded.filter { seen.insert($0.objectID).inserted }
            isLoaded = true
            errorMessage = nil
        } catch {
            isLoaded = false
            errorMessage = "Favorites could not be loaded. Your saved file has not been changed."
        }
    }

    func save(_ object: ObjectDetails) throws {
        do {
            guard isLoaded else { throw StoreError.unreadable }
            if contains(object.objectID) { return }
            guard favorites.count < limit else { throw StoreError.limitReached(limit) }
            try persist([object] + favorites)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func remove(_ id: Int) throws {
        do {
            guard isLoaded else { throw StoreError.unreadable }
            try persist(favorites.filter { $0.objectID != id })
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func cachePreview(for object: ObjectDetails, cache: ArtworkImageCache = .shared) async -> Bool {
        guard let url = ArtworkImageCache.imageURL(object.primaryImageSmall)
            ?? ArtworkImageCache.imageURL(object.primaryImage) else { return false }
        do {
            _ = try await cache.data(for: url)
            return await cache.cachedData(for: url) != nil
        } catch {
            return false
        }
    }

    private func persist(_ updated: [ObjectDetails]) throws {
        let data = try JSONEncoder().encode(updated)
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                               withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
        favorites = updated
        errorMessage = nil
    }
}
