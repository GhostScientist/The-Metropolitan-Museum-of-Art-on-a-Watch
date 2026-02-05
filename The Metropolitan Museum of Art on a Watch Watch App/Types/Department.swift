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

struct Department: Codable, Sendable {
    let departmentId: Int
    let displayName: String
}
