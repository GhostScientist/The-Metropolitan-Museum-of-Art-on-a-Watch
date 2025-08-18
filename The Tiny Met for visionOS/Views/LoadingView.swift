//
//  LoadingView.swift
//  The Tiny Met for visionOS
//
//  Created by Dakota Kim on 8/18/25.
//

import SwiftUI

struct EnhancedLoadingView: View {
    let message: String
    @State private var rotationAngle: Double = 0
    @State private var scale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.3
    
    var body: some View {
        VStack(spacing: 30) {
            ZStack {
                // Outer rotating ring
                Circle()
                    .stroke(.blue.opacity(0.3), lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                // Inner pulsing circle
                Circle()
                    .fill(.blue.opacity(pulseOpacity))
                    .frame(width: 60, height: 60)
                    .scaleEffect(scale)
                
                // Museum icon
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.blue)
                    .rotationEffect(.degrees(rotationAngle))
            }
            .onAppear {
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    rotationAngle = 360
                }
                
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    scale = 1.2
                    pulseOpacity = 0.8
                }
            }
            
            VStack(spacing: 8) {
                Text(message)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Text("Discovering masterpieces...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .opacity(0.8)
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

struct ShimmerLoadingView: View {
    @State private var shimmerOffset: CGFloat = -300
    let width: CGFloat
    let height: CGFloat
    
    init(width: CGFloat = 280, height: CGFloat = 200) {
        self.width = width
        self.height = height
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(.quaternary)
            .frame(width: width, height: height)
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.3),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmerOffset)
                    .animation(
                        .linear(duration: 1.5)
                        .repeatForever(autoreverses: false),
                        value: shimmerOffset
                    )
            }
            .onAppear {
                shimmerOffset = width + 100
            }
    }
}

struct PulsingDotLoadingView: View {
    @State private var animateFirst = false
    @State private var animateSecond = false
    @State private var animateThird = false
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(.blue)
                    .frame(width: 8, height: 8)
                    .scaleEffect(scaleFactor(for: index))
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: animateFirst
                    )
            }
        }
        .onAppear {
            animateFirst.toggle()
        }
    }
    
    private func scaleFactor(for index: Int) -> CGFloat {
        switch index {
        case 0: return animateFirst ? 1.5 : 1.0
        case 1: return animateSecond ? 1.5 : 1.0
        case 2: return animateThird ? 1.5 : 1.0
        default: return 1.0
        }
    }
}

struct WaveLoadingView: View {
    @State private var waveOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(.blue.opacity(0.2), lineWidth: 2)
                .frame(width: 60, height: 60)
            
            Circle()
                .trim(from: 0, to: 0.8)
                .stroke(.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(waveOffset))
                .animation(
                    .linear(duration: 1.0)
                    .repeatForever(autoreverses: false),
                    value: waveOffset
                )
        }
        .onAppear {
            waveOffset = 360
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        EnhancedLoadingView(message: "Loading Museum Departments...")
        
        HStack(spacing: 20) {
            ShimmerLoadingView()
            ShimmerLoadingView(width: 200, height: 150)
        }
        
        PulsingDotLoadingView()
        
        WaveLoadingView()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.black)
}