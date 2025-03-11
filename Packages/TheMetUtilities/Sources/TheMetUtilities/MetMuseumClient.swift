import Foundation

public class MetMuseumClient {
    private let baseURL = "https://collectionapi.metmuseum.org/public/collection/v1"
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    // MARK: - Public Methods
    
    /// Fetches all departments from the Met Museum API
    public func fetchDepartments() async throws -> DepartmentsResponse {
        let url = URL(string: "\(baseURL)/departments")!
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(DepartmentsResponse.self, from: data)
    }
    
    /// Fetches object details by ID
    public func fetchObjectDetails(id: Int) async throws -> ObjectDetails {
        let url = URL(string: "\(baseURL)/objects/\(id)")!
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(ObjectDetails.self, from: data)
    }
    
    /// Fetches all object IDs for a specific department
    public func fetchDepartmentObjects(departmentId: Int) async throws -> DepartmentObjectsResponse {
        let url = URL(string: "\(baseURL)/objects?departmentIds=\(departmentId)")!
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(DepartmentObjectsResponse.self, from: data)
    }
    
    /// Searches for objects based on query
    public func searchObjects(query: String) async throws -> SearchResponse {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw NSError(domain: "MetMuseumClientError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid search query"])
        }
        
        let url = URL(string: "\(baseURL)/search?q=\(encodedQuery)")!
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(SearchResponse.self, from: data)
    }
    
    /// Fetches multiple objects details in parallel
    public func fetchMultipleObjects(ids: [Int], limit: Int = 20) async throws -> [ObjectDetails] {
        // Limit the number of IDs to prevent overloading the API
        let limitedIds = Array(ids.prefix(limit))
        
        // Create and execute multiple fetch tasks in parallel
        return try await withThrowingTaskGroup(of: ObjectDetails?.self) { group in
            for id in limitedIds {
                group.addTask {
                    do {
                        return try await self.fetchObjectDetails(id: id)
                    } catch {
                        // Skip failed objects rather than failing the whole batch
                        return nil
                    }
                }
            }
            
            // Collect results, filtering out nil values
            var objects: [ObjectDetails] = []
            for try await object in group {
                if let object = object {
                    objects.append(object)
                }
            }
            
            return objects
        }
    }
} 