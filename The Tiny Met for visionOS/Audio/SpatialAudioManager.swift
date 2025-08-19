//
//  SpatialAudioManager.swift
//  The Tiny Met for visionOS
//
//  Created by Dakota Kim on 8/18/25.
//

import SwiftUI
import AVFoundation

@MainActor
class SpatialAudioManager: ObservableObject {
    static let shared = SpatialAudioManager()
    private var audioEngine: AVAudioEngine?
    private var playerNodes: [AVAudioPlayerNode] = []
    private var isAudioEnabled = false
    
    init() {
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        // Skip audio setup on visionOS for now to avoid engine initialization issues
        #if os(visionOS)
        print("Audio disabled on visionOS to avoid engine issues")
        isAudioEnabled = false
        return
        #endif
        
        audioEngine = AVAudioEngine()
        
        guard let engine = audioEngine else { 
            isAudioEnabled = false
            return 
        }
        
        // Configure audio session for spatial audio
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.ambient, mode: .default, options: [.allowBluetooth, .allowAirPlay])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
            isAudioEnabled = false
            return
        }
        
        // Start the engine
        do {
            try engine.start()
            isAudioEnabled = true
            print("Audio engine started successfully")
        } catch {
            print("Failed to start audio engine: \(error)")
            isAudioEnabled = false
        }
    }
    
    func playHoverSound() {
        guard isAudioEnabled else { return }
        generateSynthTone(frequency: 800, duration: 0.1, volume: 0.1)
    }
    
    func playTapSound() {
        guard isAudioEnabled else { return }
        generateSynthTone(frequency: 1200, duration: 0.15, volume: 0.15)
    }
    
    func playTransitionSound() {
        guard isAudioEnabled else { return }
        generateSynthTone(frequency: 600, duration: 0.2, volume: 0.12)
    }
    
    func playSuccessSound() {
        guard isAudioEnabled else { return }
        // Play a pleasant chord progression
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            let frequencies: [Float] = [523.25, 659.25, 783.99] // C-E-G chord
            for (index, frequency) in frequencies.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                    self?.generateSynthTone(frequency: frequency, duration: 0.3, volume: 0.08)
                }
            }
        }
    }
    
    private func generateSynthTone(frequency: Float, duration: Double, volume: Float) {
        guard isAudioEnabled, let engine = audioEngine else { return }
        
        let playerNode = AVAudioPlayerNode()
        let mixerNode = AVAudioMixerNode()
        
        engine.attach(playerNode)
        engine.attach(mixerNode)
        
        // Create spatial audio environment
        let environmentNode = AVAudioEnvironmentNode()
        engine.attach(environmentNode)
        
        // Connect nodes
        engine.connect(playerNode, to: mixerNode, format: nil)
        engine.connect(mixerNode, to: environmentNode, format: nil)
        engine.connect(environmentNode, to: engine.mainMixerNode, format: nil)
        
        // Generate audio buffer with sine wave
        let sampleRate: Double = 44100
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: playerNode.outputFormat(forBus: 0), frameCapacity: frameCount) else {
            return
        }
        
        buffer.frameLength = frameCount
        
        let channelData = buffer.floatChannelData?[0]
        let twoPi = 2.0 * Double.pi
        let frequencyRatio = Double(frequency) / sampleRate
        let angularFrequency = Float(twoPi * frequencyRatio)
        
        for frame in 0..<Int(frameCount) {
            let sampleValue = sin(angularFrequency * Float(frame)) * volume
            channelData?[frame] = sampleValue
        }
        
        // Apply envelope for smoother sound
        let fadeFrames = Int(frameCount / 10) // Fade in/out over 10% of duration
        for frame in 0..<fadeFrames {
            let fadeIn = Float(frame) / Float(fadeFrames)
            channelData?[frame] *= fadeIn
        }
        
        for frame in (Int(frameCount) - fadeFrames)..<Int(frameCount) {
            let fadeOut = Float(Int(frameCount) - frame) / Float(fadeFrames)
            channelData?[frame] *= fadeOut
        }
        
        // Schedule and play
        playerNode.scheduleBuffer(buffer, at: nil) {
            DispatchQueue.main.async {
                engine.detach(playerNode)
                engine.detach(mixerNode)
                engine.detach(environmentNode)
            }
        }
        
        playerNode.play()
    }
}

// View modifier for spatial audio feedback
struct SpatialAudioFeedback: ViewModifier {
    let onHover: Bool
    let onTap: Bool
    
    @StateObject private var audioManager = SpatialAudioManager.shared
    
    func body(content: Content) -> some View {
        content
            .onHover { hovering in
                if hovering && onHover {
                    audioManager.playHoverSound()
                }
            }
            .onTapGesture {
                if onTap {
                    audioManager.playTapSound()
                }
            }
    }
}

extension View {
    func spatialAudio(onHover: Bool = false, onTap: Bool = false) -> some View {
        self.modifier(SpatialAudioFeedback(onHover: onHover, onTap: onTap))
    }
}