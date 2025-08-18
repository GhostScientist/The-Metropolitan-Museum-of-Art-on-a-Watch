//
//  HapticManager.swift
//  The Tiny Met for visionOS
//
//  Created by Dakota Kim on 8/18/25.
//

import SwiftUI

@MainActor
class HapticManager: ObservableObject {
    static let shared = HapticManager()
    
    private init() {}
    
    func lightImpact() {
        #if os(visionOS)
        // visionOS doesn't have haptic feedback, so we use visual feedback instead
        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
            // Visual feedback is handled by the UI animations
        }
        #else
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        #endif
    }
    
    func mediumImpact() {
        #if os(visionOS)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            // Visual feedback through animations
        }
        #else
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        #endif
    }
    
    func success() {
        #if os(visionOS)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            // Success animation feedback
        }
        #else
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        #endif
    }
}

// Enhanced view modifier with haptic feedback
struct EnhancedFeedback: ViewModifier {
    let onHover: Bool
    let onTap: Bool
    
    @StateObject private var audioManager = SpatialAudioManager.shared
    @StateObject private var hapticManager = HapticManager.shared
    
    func body(content: Content) -> some View {
        content
            .onHover { hovering in
                if hovering && onHover {
                    audioManager.playHoverSound()
                    hapticManager.lightImpact()
                }
            }
            .onTapGesture {
                if onTap {
                    audioManager.playTapSound()
                    hapticManager.mediumImpact()
                }
            }
    }
}

extension View {
    func enhancedFeedback(onHover: Bool = false, onTap: Bool = false) -> some View {
        self.modifier(EnhancedFeedback(onHover: onHover, onTap: onTap))
    }
}