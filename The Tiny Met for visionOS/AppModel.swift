//
//  AppModel.swift
//  The Tiny Met for visionOS
//
//  Created by Dakota Kim on 8/18/25.
//

import SwiftUI

/// Maintains app-wide state
@MainActor
@Observable
class AppModel {
    let immersiveSpaceID = "ImmersiveSpace"
    let galleryVolumeID = "GalleryVolume"
    
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed
    
    // Met Museum data
    var departments: [Department] = []
    var selectedDepartment: Department?
    var isLoadingDepartments = false
    var errorMessage: String?
    
    private let metMuseumClient = MetMuseumClient()
    
    func fetchDepartments() async {
        isLoadingDepartments = true
        errorMessage = nil
        
        do {
            departments = try await metMuseumClient.fetchDepartments().departments
            print("Loaded \(departments.count) departments for visionOS")
            isLoadingDepartments = false
            
            // Play success feedback when departments load
            await SpatialAudioManager.shared.playSuccessSound()
            await HapticManager.shared.success()
        } catch {
            if error.isInternetConnectionError {
                errorMessage = "No internet connection"
            } else {
                errorMessage = "Failed to fetch departments"
            }
            isLoadingDepartments = false
        }
    }
}
