//
//  Search.swift
//  The Tiny Met Watch App
//
//  Created by Dakota Kim on 4/1/24.
//

import Foundation

struct SearchResult: Codable, Sendable {
    let total: Int
    let objectIDs: [Int]

    private enum CodingKeys: String, CodingKey {
        case total, objectIDs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        total = try container.decode(Int.self, forKey: .total)
        // The Met API returns `"objectIDs": null` when a search has no hits.
        objectIDs = try container.decodeIfPresent([Int].self, forKey: .objectIDs) ?? []
    }
}

struct SearchQuery: Sendable {
    var query: String
    var isHighlight: Bool?
    var title: Bool?
    var tags: Bool?
    var departmentId: Int?
    var isOnView: Bool?
    var artistOrCulture: Bool?
    var medium: String?
    var hasImages: Bool?
    var geoLocation: String?
    var dateBegin: Int?
    var dateEnd: Int?

    init(query: String) {
        self.query = query
    }
}
