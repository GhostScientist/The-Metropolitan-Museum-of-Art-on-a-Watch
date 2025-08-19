//
//  Objects.swift
//  The Tiny Met for visionOS
//
//  Created by Dakota Kim on 8/18/25.
//

import Foundation

struct ObjectIDs: Codable {
    let total: Int
    let objectIDs: [Int]
    
    var firstTen: [Int] {
        return Array(objectIDs.prefix(10))
    }
    
    var allAsInt: [Int] {
        return Array(objectIDs)
    }
}

struct ObjectDetails: Codable, Identifiable, Hashable {
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