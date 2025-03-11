//
//  AppModel.swift
//  The Met for VisionOS
//
//  Created by Dakota Kim on 1/20/25.
//

import SwiftUI
import TheMetUtilities

/// Maintains app-wide state
@MainActor
@Observable
class AppModel {
    // Gallery window state (renamed from immersive space)
    let immersiveSpaceID = "gallery-window" // renamed for clarity but keeping variable name for compatibility
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed
    
    // User preferences
    var preferredDepartments: [Int] = []
    var favoriteArtworks: [Int] = []
    var recentlyViewedArtworks: [ObjectDetails] = []
    var viewingHistory: [ViewingHistoryEntry] = []
    
    // Active browsing state
    var currentDepartment: Department?
    var currentArtwork: ObjectDetails?
    var currentSearchTerm: String = ""
    
    // App settings
    var useHighQualityImages: Bool = true
    var showLabelsInGallery: Bool = true
    var galleryBrowsingStyle: GalleryBrowsingStyle = .modern
    var artworkFrameStyle: FrameStyle = .modern
    
    // Enums for app settings
    enum GalleryBrowsingStyle: String, CaseIterable, Identifiable {
        case modern = "Modern"
        case classical = "Classical"
        case minimalist = "Minimalist"
        
        var id: String { self.rawValue }
    }
    
    enum FrameStyle: String, CaseIterable, Identifiable {
        case none = "No Frame"
        case simple = "Simple"
        case modern = "Modern"
        case ornate = "Ornate" 
        
        var id: String { self.rawValue }
    }
    
    // MARK: - Methods
    
    func closeGallery() {
        // Method to close the gallery window
        NotificationCenter.default.post(name: NSNotification.Name("CloseGalleryWindow"), object: nil)
        immersiveSpaceState = .closed
    }
    
    func addToViewingHistory(artwork: ObjectDetails) {
        // Create a new history entry
        let entry = ViewingHistoryEntry(
            objectID: artwork.objectID,
            title: artwork.title,
            artist: artwork.artistDisplayName,
            image: artwork.primaryImageSmall,
            timestamp: Date()
        )
        
        // Add to viewing history (ensure no duplicates)
        if let existingIndex = viewingHistory.firstIndex(where: { $0.objectID == artwork.objectID }) {
            viewingHistory.remove(at: existingIndex)
        }
        
        // Add to the beginning of the array
        viewingHistory.insert(entry, at: 0)
        
        // Limit history to 50 items
        if viewingHistory.count > 50 {
            viewingHistory = Array(viewingHistory.prefix(50))
        }
        
        // Add to recently viewed (limited to last 10)
        if let existingIndex = recentlyViewedArtworks.firstIndex(where: { $0.objectID == artwork.objectID }) {
            recentlyViewedArtworks.remove(at: existingIndex)
        }
        recentlyViewedArtworks.insert(artwork, at: 0)
        
        if recentlyViewedArtworks.count > 10 {
            recentlyViewedArtworks = Array(recentlyViewedArtworks.prefix(10))
        }
    }
    
    func toggleFavorite(artworkID: Int) {
        if favoriteArtworks.contains(artworkID) {
            favoriteArtworks.removeAll { $0 == artworkID }
        } else {
            favoriteArtworks.append(artworkID)
        }
    }
    
    func isFavorite(artworkID: Int) -> Bool {
        return favoriteArtworks.contains(artworkID)
    }
    
    func togglePreferredDepartment(departmentID: Int) {
        if preferredDepartments.contains(departmentID) {
            preferredDepartments.removeAll { $0 == departmentID }
        } else {
            preferredDepartments.append(departmentID)
        }
    }
    
    func clearHistory() {
        viewingHistory.removeAll()
        recentlyViewedArtworks.removeAll()
    }
}

// Model for viewing history entries
struct ViewingHistoryEntry: Identifiable, Equatable {
    let id = UUID()
    let objectID: Int
    let title: String
    let artist: String
    let image: String
    let timestamp: Date
    
    static func == (lhs: ViewingHistoryEntry, rhs: ViewingHistoryEntry) -> Bool {
        return lhs.objectID == rhs.objectID
    }
}
