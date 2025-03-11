import Foundation
import TheMetUtilities

// Add Sendable conformance to types that need it
extension MetMuseumClient: @retroactive @unchecked Sendable {}
extension ObjectIDs: @retroactive @unchecked Sendable {}
extension ObjectDetails: @retroactive @unchecked Sendable {}
extension SearchResult: @retroactive @unchecked Sendable {}
extension DepartmentResponse: @retroactive @unchecked Sendable {} 