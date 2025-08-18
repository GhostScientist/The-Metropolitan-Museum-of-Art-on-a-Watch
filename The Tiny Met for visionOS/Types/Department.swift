//
//  Department.swift
//  The Tiny Met for visionOS
//
//  Created by Dakota Kim on 8/18/25.
//

import Foundation

struct Department: Codable, Identifiable, Hashable {
    let departmentId: Int
    let displayName: String
    
    var id: Int {
        departmentId
    }
}

struct DepartmentResponse: Codable {
    let departments: [Department]
}