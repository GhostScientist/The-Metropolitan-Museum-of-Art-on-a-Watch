//
//  PhysicsAnimationView.swift
//  The Tiny Met for visionOS
//
//  Created by Dakota Kim on 8/18/25.
//

import SwiftUI

struct FloatingCardPhysicsModifier: ViewModifier {
    @State private var position: CGPoint = CGPoint(x: 0, y: 0)
    @State private var velocity: CGPoint = CGPoint(x: 0, y: 0)
    @State private var isHovered = false
    @State private var timer: Timer?
    
    let floatRange: CGFloat = 3.0
    let dampening: CGFloat = 0.98
    let springStrength: CGFloat = 0.02
    
    func body(content: Content) -> some View {
        content
            .offset(x: position.x, y: position.y)
            .onHover { hovering in
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    isHovered = hovering
                }
                
                if hovering {
                    startPhysicsSimulation()
                } else {
                    stopPhysicsSimulation()
                }
            }
            .onAppear {
                startGentleFloat()
            }
    }
    
    private func startGentleFloat() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            let targetX = CGFloat.random(in: -floatRange...floatRange)
            let targetY = CGFloat.random(in: -floatRange...floatRange)
            
            withAnimation(.easeInOut(duration: Double.random(in: 2.0...4.0))) {
                position.x = targetX * 0.3
                position.y = targetY * 0.3
            }
        }
    }
    
    private func startPhysicsSimulation() {
        stopPhysicsSimulation()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            // Add some randomness for natural movement
            let randomForceX = CGFloat.random(in: -0.1...0.1)
            let randomForceY = CGFloat.random(in: -0.1...0.1)
            
            // Spring force towards center
            let springForceX = -position.x * springStrength
            let springForceY = -position.y * springStrength
            
            // Update velocity
            velocity.x += springForceX + randomForceX
            velocity.y += springForceY + randomForceY
            
            // Apply dampening
            velocity.x *= dampening
            velocity.y *= dampening
            
            // Update position
            position.x += velocity.x
            position.y += velocity.y
            
            // Constrain within bounds
            let maxOffset: CGFloat = isHovered ? floatRange * 2 : floatRange
            position.x = max(-maxOffset, min(maxOffset, position.x))
            position.y = max(-maxOffset, min(maxOffset, position.y))
        }
    }
    
    private func stopPhysicsSimulation() {
        timer?.invalidate()
        timer = nil
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.9)) {
            position = .zero
            velocity = .zero
        }
    }
}

struct MagneticFieldEffect: ViewModifier {
    @State private var magneticOffset: CGSize = .zero
    @State private var magneticStrength: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .offset(magneticOffset)
            .background {
                // Invisible magnetic field detector
                Rectangle()
                    .fill(.clear)
                    .frame(width: 400, height: 400)
                    .onContinuousHover { phase in
                        switch phase {
                        case .active(let location):
                            let centerX: CGFloat = 200
                            let centerY: CGFloat = 200
                            
                            let deltaX = location.x - centerX
                            let deltaY = location.y - centerY
                            let distance = sqrt(deltaX * deltaX + deltaY * deltaY)
                            
                            if distance < 150 {
                                let strength = (150 - distance) / 150
                                let attraction = strength * 15
                                
                                withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.6)) {
                                    magneticOffset = CGSize(
                                        width: (deltaX / distance) * attraction,
                                        height: (deltaY / distance) * attraction
                                    )
                                    magneticStrength = strength
                                }
                            }
                        case .ended:
                            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                                magneticOffset = .zero
                                magneticStrength = 0
                            }
                        }
                    }
            }
            .scaleEffect(1 + magneticStrength * 0.1)
    }
}

struct GravityWellEffect: ViewModifier {
    @State private var orbitAngle: Double = 0
    @State private var isOrbiting = false
    @State private var orbitRadius: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .offset(
                x: isOrbiting ? cos(orbitAngle * .pi / 180) * orbitRadius : 0,
                y: isOrbiting ? sin(orbitAngle * .pi / 180) * orbitRadius : 0
            )
            .onHover { hovering in
                if hovering {
                    withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                        orbitAngle = 360
                    }
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        isOrbiting = true
                        orbitRadius = 20
                    }
                } else {
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.9)) {
                        isOrbiting = false
                        orbitRadius = 0
                        orbitAngle = 0
                    }
                }
            }
    }
}

extension View {
    func floatingPhysics() -> some View {
        self.modifier(FloatingCardPhysicsModifier())
    }
    
    func magneticField() -> some View {
        self.modifier(MagneticFieldEffect())
    }
    
    func gravityWell() -> some View {
        self.modifier(GravityWellEffect())
    }
}

#Preview {
    ScrollView {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 25),
            GridItem(.flexible(), spacing: 25),
            GridItem(.flexible(), spacing: 25)
        ], spacing: 25) {
            ForEach(0..<9) { index in
                RoundedRectangle(cornerRadius: 16)
                    .fill(.blue.gradient)
                    .frame(width: 200, height: 150)
                    .overlay {
                        Text("Card \(index + 1)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                    .floatingPhysics()
                    .magneticField()
            }
        }
        .padding(40)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.black)
}