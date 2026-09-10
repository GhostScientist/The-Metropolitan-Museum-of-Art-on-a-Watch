//
//  Object.swift
//  The Tiny Met
//
//  Created by Dakota Kim on 10/28/24.
//

struct Object: Identifiable, Sendable {
    let id: Int
    let title: String
    let objectName: String

    var objectID: Int { id }
}
