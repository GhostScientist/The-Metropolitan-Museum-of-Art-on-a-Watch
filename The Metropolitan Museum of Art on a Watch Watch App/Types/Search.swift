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

    init(total: Int, objectIDs: [Int]) {
        self.total = total
        self.objectIDs = objectIDs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        total = try container.decode(Int.self, forKey: .total)
        objectIDs = try container.decodeIfPresent([Int].self, forKey: .objectIDs) ?? []
    }
}

struct SearchQuery {
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
