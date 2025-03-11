import Foundation

// MARK: - Department Models
public struct DepartmentsResponse: Codable {
    public let departments: [Department]
    
    public init(departments: [Department]) {
        self.departments = departments
    }
}

public struct Department: Codable, Identifiable, Hashable {
    public let departmentId: Int
    public let displayName: String
    
    public var id: Int {
        return departmentId
    }
    
    public init(departmentId: Int, displayName: String) {
        self.departmentId = departmentId
        self.displayName = displayName
    }
    
    public static func == (lhs: Department, rhs: Department) -> Bool {
        return lhs.departmentId == rhs.departmentId
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(departmentId)
    }
}

// MARK: - Object Models
public struct ObjectDetailsResponse: Codable {
    public let objectID: Int
    public let primaryImage: String
    public let primaryImageSmall: String
    public let additionalImages: [String]
    public let title: String
    public let culture: String
    public let period: String
    public let dynasty: String
    public let artistRole: String
    public let artistDisplayName: String
    public let artistDisplayBio: String
    public let medium: String
    public let dimensions: String
    public let creditLine: String
    public let department: String
    public let objectName: String
    public let objectDate: String
    public let isHighlight: Bool
    public let isPublicDomain: Bool
    
    public init(
        objectID: Int,
        primaryImage: String,
        primaryImageSmall: String,
        additionalImages: [String],
        title: String,
        culture: String,
        period: String,
        dynasty: String,
        artistRole: String,
        artistDisplayName: String,
        artistDisplayBio: String,
        medium: String,
        dimensions: String,
        creditLine: String,
        department: String,
        objectName: String,
        objectDate: String,
        isHighlight: Bool,
        isPublicDomain: Bool
    ) {
        self.objectID = objectID
        self.primaryImage = primaryImage
        self.primaryImageSmall = primaryImageSmall
        self.additionalImages = additionalImages
        self.title = title
        self.culture = culture
        self.period = period
        self.dynasty = dynasty
        self.artistRole = artistRole
        self.artistDisplayName = artistDisplayName
        self.artistDisplayBio = artistDisplayBio
        self.medium = medium
        self.dimensions = dimensions
        self.creditLine = creditLine
        self.department = department
        self.objectName = objectName
        self.objectDate = objectDate
        self.isHighlight = isHighlight
        self.isPublicDomain = isPublicDomain
    }
}

// Alias for more readable code
public typealias ObjectDetails = ObjectDetailsResponse

// MARK: - Department Objects Response
public struct DepartmentObjectsResponse: Codable {
    public let objectIDs: [Int]
    
    public init(objectIDs: [Int]) {
        self.objectIDs = objectIDs
    }
}

// MARK: - Search Response
public struct SearchResponse: Codable {
    public let total: Int
    public let objectIDs: [Int]?
    
    public init(total: Int, objectIDs: [Int]?) {
        self.total = total
        self.objectIDs = objectIDs
    }
} 