//
//  Department.swift
//  The Metropolitan Museum of Art on a Watch Watch App
//
//  Created by Dakota Kim on 4/1/24.
//

import Foundation

struct DepartmentResponse: Codable {
    let departments: [Department]
}

struct Department: Codable {
    let departmentId: Int
    let displayName: String
}
