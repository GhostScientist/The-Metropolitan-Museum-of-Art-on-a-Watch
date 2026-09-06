//
//  CachedObjectDetails.swift
//  The Tiny Met
//
//  Created by Dakota Kim on 10/28/24.
//

import Foundation

final class CachedObjectDetails: NSObject {
    let details: ObjectDetails
    
    init(details: ObjectDetails) {
        self.details = details
        super.init()
    }
}

actor ObjectCache {
    static let shared = ObjectCache()
    private let cache = NSCache<NSNumber, CachedObjectDetails>()
    private let directory: URL
    private let maxEntries: Int
    private let maxBytes: Int

    init(directory: URL = CacheStorage.directory(named: "Objects"),
         maxEntries: Int = 100, maxBytes: Int = 5 * 1_024 * 1_024) {
        self.directory = directory
        self.maxEntries = max(0, maxEntries)
        self.maxBytes = max(0, maxBytes)
        cache.countLimit = max(1, maxEntries)
        try? CacheStorage.prepare(directory)
        try? CacheStorage.trim(directory, maxEntries: self.maxEntries, maxBytes: self.maxBytes)
    }

    func object(for id: Int) -> ObjectDetails? {
        if let details = cache.object(forKey: NSNumber(value: id))?.details {
            return details
        }
        let file = directory.appendingPathComponent("\(id).cache")
        guard let data = try? Data(contentsOf: file),
              let details = try? JSONDecoder().decode(ObjectDetails.self, from: data),
              details.objectID == id else {
            try? FileManager.default.removeItem(at: file)
            return nil
        }
        cache.setObject(CachedObjectDetails(details: details), forKey: NSNumber(value: id))
        try? FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: file.path)
        return details
    }

    func cache(_ object: ObjectDetails) {
        guard maxEntries > 0, maxBytes > 0 else { return }
        let cached = CachedObjectDetails(details: object)
        cache.setObject(cached, forKey: NSNumber(value: object.objectID))
        guard let data = try? JSONEncoder().encode(object), data.count <= maxBytes else { return }
        do {
            try CacheStorage.prepare(directory)
            try data.write(to: directory.appendingPathComponent("\(object.objectID).cache"), options: .atomic)
            try CacheStorage.trim(directory, maxEntries: maxEntries, maxBytes: maxBytes)
        } catch {
            // A disposable cache must not prevent browsing when storage is unavailable.
        }
    }
}

enum CacheStorage {
    static func directory(named name: String) -> URL {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Caches")
        return base.appendingPathComponent("TheTinyMet", isDirectory: true)
            .appendingPathComponent(name, isDirectory: true)
    }

    static func prepare(_ directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    static func trim(_ directory: URL, maxEntries: Int, maxBytes: Int) throws {
        let files = try FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ).filter { $0.pathExtension == "cache" }
        let entries = try files.map { file -> (URL, Int, Date) in
            let values = try file.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
            return (file, values.fileSize ?? 0, values.contentModificationDate ?? .distantPast)
        }.sorted { $0.2 < $1.2 }
        var bytes = entries.reduce(0) { $0 + $1.1 }
        var count = entries.count
        for (file, size, _) in entries where count > maxEntries || bytes > maxBytes {
            try FileManager.default.removeItem(at: file)
            count -= 1
            bytes -= size
        }
    }
}
