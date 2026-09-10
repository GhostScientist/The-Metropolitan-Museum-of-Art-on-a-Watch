//
//  Department.swift
//  "The Tiny Met" Watch App
//
//  Created by Dakota Kim on 4/1/24.
//

import Foundation

struct DepartmentResponse: Codable, Sendable {
    let departments: [Department]
}

struct Department: Codable, Sendable, Identifiable, Hashable {
    let departmentId: Int
    let displayName: String

    var id: Int { departmentId }

    /// Name of the bundled hero image for this department, if one exists.
    var imageAssetName: String { "\(departmentId)" }
}
