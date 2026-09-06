//
//  Objects.swift
//  The Tiny Met Watch App
//
//  Created by Dakota Kim on 4/1/24.
//

import Foundation

struct ObjectIDs: Codable, Sendable {
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
    
    var firstTen: [Int] {
        return Array(objectIDs.prefix(10))
    }
    
    var allAsInt: [Int] {
        return Array(objectIDs)
    }
}

struct ObjectDetails: Codable, Identifiable, Hashable, Sendable {
    var id: Int{
        return objectID
    }
    
    let objectID: Int
    let isHighlight: Bool
    let accessionYear: String
    let isPublicDomain: Bool
    let primaryImage: String
    let primaryImageSmall: String
    let department: String
    let objectName: String
    let title: String
    let culture: String
    let period: String
    let artistDisplayName: String
    let artistDisplayBio: String
    let objectDate: String
    let medium: String
    let dimensions: String
    let creditLine: String
    let geographyType: String
    let city: String
    let country: String
    let classification: String
    let objectURL: String
}
