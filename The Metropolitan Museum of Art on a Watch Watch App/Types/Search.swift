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
