//
//  TheMetMuseumAPI.swift
//  The Met: Art Around The Clock Watch App
//
//  Created by Dakota Kim on 4/1/24.
//

import Foundation
import os

actor MetMuseumClient {
    private let baseURL = "https://collectionapi.metmuseum.org/public/collection/v1"
    private let logger = Logger(subsystem: "com.dakotakim.TheTinyMet", category: "API")

    func fetchDepartments() async throws -> DepartmentResponse {
        let url = URL(string: "\(baseURL)/departments")!
        let (data, response) = try await URLSession.shared.data(from: url)
        try validateResponse(response)
        return try JSONDecoder().decode(DepartmentResponse.self, from: data)
    }

    func searchDepartmentForObjectsBySearchTerm(searchTerm: String, departmentId: Int) async throws -> SearchResult {
        var components = URLComponents(string: "\(baseURL)/search")!
        components.queryItems = [
            URLQueryItem(name: "departmentId", value: String(departmentId)),
            URLQueryItem(name: "q", value: searchTerm)
        ]
        let (data, response) = try await URLSession.shared.data(from: components.url!)
        try validateResponse(response)
        return try JSONDecoder().decode(SearchResult.self, from: data)
    }

    func fetchObjects(departmentId: Int) async throws -> ObjectIDs {
        logger.debug("Fetching objects for department \(departmentId)")
        let url = URL(string: "\(baseURL)/objects?departmentIds=\(departmentId)")!
        let (data, response) = try await URLSession.shared.data(from: url)
        try validateResponse(response)
        return try JSONDecoder().decode(ObjectIDs.self, from: data)
    }

    func searchObjects(query: SearchQuery) async throws -> SearchResult {
        var urlComponents = URLComponents(string: "\(baseURL)/search")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "q", value: query.query)
        ]

        if let isHighlight = query.isHighlight {
            queryItems.append(URLQueryItem(name: "isHighlight", value: String(isHighlight)))
        }
        if let title = query.title {
            queryItems.append(URLQueryItem(name: "title", value: String(title)))
        }
        if let tags = query.tags {
            queryItems.append(URLQueryItem(name: "tags", value: String(tags)))
        }
        if let departmentId = query.departmentId {
            queryItems.append(URLQueryItem(name: "departmentId", value: String(departmentId)))
        }
        if let isOnView = query.isOnView {
            queryItems.append(URLQueryItem(name: "isOnView", value: String(isOnView)))
        }
        if let artistOrCulture = query.artistOrCulture {
            queryItems.append(URLQueryItem(name: "artistOrCulture", value: String(artistOrCulture)))
        }
        if let medium = query.medium {
            queryItems.append(URLQueryItem(name: "medium", value: medium))
        }
        if let hasImages = query.hasImages {
            queryItems.append(URLQueryItem(name: "hasImages", value: String(hasImages)))
        }
        if let geoLocation = query.geoLocation {
            queryItems.append(URLQueryItem(name: "geoLocation", value: geoLocation))
        }
        if let dateBegin = query.dateBegin, let dateEnd = query.dateEnd {
            queryItems.append(URLQueryItem(name: "dateBegin", value: String(dateBegin)))
            queryItems.append(URLQueryItem(name: "dateEnd", value: String(dateEnd)))
        }

        urlComponents.queryItems = queryItems

        let (data, response) = try await URLSession.shared.data(from: urlComponents.url!)
        try validateResponse(response)
        return try JSONDecoder().decode(SearchResult.self, from: data)
    }

    func fetchObjectDetails(objectID: Int) async throws -> ObjectDetails {
        let url = URL(string: "\(baseURL)/objects/\(objectID)")!
        let (data, response) = try await URLSession.shared.data(from: url)
        try validateResponse(response)
        return try JSONDecoder().decode(ObjectDetails.self, from: data)
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else { return }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
