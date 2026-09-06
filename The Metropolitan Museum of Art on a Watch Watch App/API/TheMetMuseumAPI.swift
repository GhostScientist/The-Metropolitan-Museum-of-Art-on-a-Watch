//
//  TheMetMuseumAPI.swift
//  The Met: Art Around The Clock Watch App
//
//  Created by Dakota Kim on 4/1/24.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

protocol MetMuseumServing: Sendable {
    func fetchDepartments() async throws -> DepartmentResponse
    func searchDepartmentForObjectsBySearchTerm(searchTerm: String, departmentId: Int) async throws -> SearchResult
    func fetchObjects(departmentId: Int) async throws -> ObjectIDs
    func fetchObjectDetails(objectID: Int) async throws -> ObjectDetails
}

enum MetMuseumError: Error, LocalizedError, Equatable {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "The museum request could not be created."
        case .invalidResponse: return "The museum returned an invalid response."
        case .httpStatus(let status): return "The museum returned an error (HTTP \(status)). Please try again."
        }
    }
}

struct PreviewMetMuseumClient: MetMuseumServing {
    static let department = Department(departmentId: 11, displayName: "European Paintings")
    static let artwork = ObjectDetails(
        objectID: 436535,
        isHighlight: true,
        accessionYear: "1993",
        isPublicDomain: true,
        primaryImage: "",
        primaryImageSmall: "",
        department: "European Paintings",
        objectName: "Painting",
        title: "Wheat Field with Cypresses",
        culture: "",
        period: "",
        artistDisplayName: "Vincent van Gogh",
        artistDisplayBio: "Dutch, 1853–1890",
        objectDate: "1889",
        medium: "Oil on canvas",
        dimensions: "73 × 93.4 cm",
        creditLine: "Purchase, The Annenberg Foundation Gift, 1993",
        geographyType: "",
        city: "",
        country: "",
        classification: "Paintings",
        objectURL: ""
    )

    func fetchDepartments() async throws -> DepartmentResponse {
        DepartmentResponse(departments: [Self.department])
    }

    func fetchObjects(departmentId: Int) async throws -> ObjectIDs {
        let ids = departmentId == Self.department.departmentId ? [Self.artwork.objectID] : []
        return ObjectIDs(total: ids.count, objectIDs: ids)
    }

    func searchDepartmentForObjectsBySearchTerm(searchTerm: String, departmentId: Int) async throws -> SearchResult {
        let query = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        let matches = query.isEmpty || "\(Self.artwork.title) \(Self.artwork.artistDisplayName)"
            .localizedCaseInsensitiveContains(query)
        let ids = departmentId == Self.department.departmentId && matches ? [Self.artwork.objectID] : []
        return SearchResult(total: ids.count, objectIDs: ids)
    }

    func fetchObjectDetails(objectID: Int) async throws -> ObjectDetails {
        guard objectID == Self.artwork.objectID else { throw URLError(.resourceUnavailable) }
        return Self.artwork
    }
}

final class MetMuseumClient: MetMuseumServing {
    private let baseURL = "https://collectionapi.metmuseum.org/public/collection/v1"
    private let session: URLSession
    private let cache: ObjectCache?

    init(session: URLSession = .shared, cache: ObjectCache? = .shared) {
        self.session = session
        self.cache = cache
    }

    private func request<Value: Decodable>(_ path: String, queryItems: [URLQueryItem] = []) async throws -> Value {
        guard var components = URLComponents(string: "\(baseURL)/\(path)") else {
            throw MetMuseumError.invalidURL
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
            // A literal plus must not be interpreted as a form-encoded space.
            components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        }
        guard let url = components.url else { throw MetMuseumError.invalidURL }
        let (data, response) = try await session.data(from: url)
        try Task.checkCancellation()
        guard let response = response as? HTTPURLResponse else { throw MetMuseumError.invalidResponse }
        guard (200..<300).contains(response.statusCode) else {
            throw MetMuseumError.httpStatus(response.statusCode)
        }
        return try JSONDecoder().decode(Value.self, from: data)
    }

    func fetchDepartments() async throws -> DepartmentResponse {
        try await request("departments")
    }
    
    func searchDepartmentForObjectsBySearchTerm(searchTerm: String, departmentId: Int) async throws -> SearchResult {
        try await request("search", queryItems: [
            URLQueryItem(name: "departmentId", value: String(departmentId)),
            URLQueryItem(name: "q", value: searchTerm)
        ])
    }
    
    func fetchObjects(departmentId: Int) async throws -> ObjectIDs {
        try await request("objects", queryItems: [
            URLQueryItem(name: "departmentIds", value: String(departmentId))
        ])
    }
    
    func searchObjects(query: SearchQuery) async throws -> SearchResult {
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
            
            return try await request("search", queryItems: queryItems)
        }
    
    func fetchObjectDetails(objectID: Int) async throws -> ObjectDetails {
        try Task.checkCancellation()
        if let object = await cache?.object(for: objectID) {
            return object
        }
        let object: ObjectDetails = try await request("objects/\(objectID)")
        await cache?.cache(object)
        return object
    }
}
