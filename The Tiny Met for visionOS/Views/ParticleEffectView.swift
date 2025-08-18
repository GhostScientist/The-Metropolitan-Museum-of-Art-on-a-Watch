//
//  ParticleEffectView.swift
//  The Tiny Met for visionOS
//
//  Created by Dakota Kim on 8/18/25.
//

import SwiftUI

struct ParticleEffectView: View {
    @State private var particles: [Particle] = []
    let particleCount = 20
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
                    .scaleEffect(particle.scale)
            }
        }
        .onAppear {
            createParticles()
            animateParticles()
        }
    }
    
    private func createParticles() {
        particles = (0..<particleCount).map { _ in
            Particle(
                position: CGPoint(x: 200, y: 200),
                color: [.blue, .purple, .pink, .cyan, .teal].randomElement() ?? .blue,
                size: Double.random(in: 2...6),
                opacity: Double.random(in: 0.3...0.8),
                scale: Double.random(in: 0.5...1.0)
            )
        }
    }
    
    private func animateParticles() {
        for (index, _) in particles.enumerated() {
            let delay = Double(index) * 0.1
            
            withAnimation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
                .delay(delay)
            ) {
                particles[index].position = CGPoint(
                    x: Double.random(in: 0...400),
                    y: Double.random(in: 0...400)
                )
                particles[index].scale = Double.random(in: 0.3...1.5)
                particles[index].opacity = Double.random(in: 0.1...1.0)
            }
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var color: Color
    var size: Double
    var opacity: Double
    var scale: Double
}

struct FloatingParticleEffect: View {
    @State private var isAnimating = false
    let colors: [Color]
    
    init(colors: [Color] = [.blue, .purple, .pink, .cyan]) {
        self.colors = colors
    }
    
    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(colors.randomElement() ?? .blue)
                    .frame(width: CGFloat.random(in: 1...3))
                    .offset(
                        x: isAnimating ? CGFloat.random(in: -50...50) : 0,
                        y: isAnimating ? CGFloat.random(in: -50...50) : 0
                    )
                    .opacity(isAnimating ? Double.random(in: 0.2...0.8) : 0)
                    .animation(
                        .easeInOut(duration: Double.random(in: 1.5...3.0))
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    ParticleEffectView()
        .frame(width: 400, height: 400)
        .background(.black)
}