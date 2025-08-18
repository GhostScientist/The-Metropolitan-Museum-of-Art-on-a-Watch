//
//  Search.swift
//  The Tiny Met for visionOS
//
//  Created by Dakota Kim on 8/18/25.
//

import Foundation

struct SearchQuery {
    let query: String
    var isHighlight: Bool? = nil
    var title: Bool? = nil
    var tags: Bool? = nil
    var departmentId: Int? = nil
    var isOnView: Bool? = nil
    var artistOrCulture: Bool? = nil
    var medium: String? = nil
    var hasImages: Bool? = nil
    var geoLocation: String? = nil
    var dateBegin: Int? = nil
    var dateEnd: Int? = nil
}

struct SearchResult: Codable {
    let total: Int
    let objectIDs: [Int]
}