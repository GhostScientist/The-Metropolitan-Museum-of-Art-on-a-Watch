//
//  OnboardingView.swift
//  The Met for VisionOS
//
//  Created by Dakota Kim on 1/20/25.
//

import SwiftUI
// Remove RealityKit import since we don't need it anymore
// import RealityKit

struct OnboardingView: View {
    var onComplete: () -> Void
    
    @State private var currentPage = 0
    @State private var showContinueButton = false
    @State private var rotationAngle: Double = 0
    @State private var floatAnimation: Bool = false
    @State private var scaleAnimation: CGFloat = 1.0
    
    private let pages = [
        OnboardingPage(
            title: "Welcome to The Met",
            description: "Experience the Metropolitan Museum of Art's priceless collection in a revolutionary spatial environment.",
            imageName: "building.columns.fill",
            color: Color(red: 0.9, green: 0.3, blue: 0.3),
            modelName: "museum"
        ),
        OnboardingPage(
            title: "Discover Masterpieces",
            description: "Browse through centuries of artistic genius across different departments and periods.",
            imageName: "photo.stack.fill",
            color: Color(red: 0.3, green: 0.6, blue: 0.9),
            modelName: "artworks"
        ),
        OnboardingPage(
            title: "Immersive Experience",
            description: "Step into the artwork and explore details that would be impossible to see in person.",
            imageName: "eye.fill",
            color: Color(red: 0.5, green: 0.3, blue: 0.8),
            modelName: "immersive"
        ),
        OnboardingPage(
            title: "Your Personal Gallery",
            description: "Create your own exhibition with favorite artworks displayed in a customizable virtual space.",
            imageName: "person.fill.viewfinder",
            color: Color(red: 0.1, green: 0.7, blue: 0.6),
            modelName: "gallery"
        )
    ]
    
    var body: some View {
        ZStack {
            // Background - subtle depth layers
            ZStack {
                // Deep background layer
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.8), Color.black]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Atmospheric particle effects
                ForEach(0..<30) { index in
                    Circle()
                        .fill(Color.white.opacity(Double.random(in: 0.02...0.1)))
                        .frame(width: CGFloat.random(in: 2...8), height: CGFloat.random(in: 2...8))
                        .position(x: CGFloat.random(in: 0...600), y: CGFloat.random(in: 0...800))
                        .blur(radius: CGFloat.random(in: 1...3))
                }
            }
            
            // Main content
            VStack(spacing: 20) {
                Spacer().frame(height: 30)
                
                // 2D visual elements - replacing 3D models
                ZStack {
                    Circle()
                        .fill(pages[currentPage].color.opacity(0.2))
                        .frame(width: 240, height: 240)
                    
                    Circle()
                        .fill(pages[currentPage].color.opacity(0.4))
                        .frame(width: 200, height: 200)
                    
                    Image(systemName: pages[currentPage].imageName)
                        .font(.system(size: 80))
                        .foregroundStyle(.white)
                        .symbolEffect(.pulse, options: .repeating)
                        .scaleEffect(scaleAnimation)
                        .offset(y: floatAnimation ? -5 : 5)
                }
                .frame(height: 250)
                .padding(.vertical, 10)
                .onAppear {
                    withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                        floatAnimation = true
                    }
                    withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                        scaleAnimation = 1.05
                    }
                }
                
                // Title and description with depth
                VStack(spacing: 15) {
                    Text(pages[currentPage].title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                    
                    Text(pages[currentPage].description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 500)
                        .padding(.horizontal)
                }
                .padding()
                .frame(maxHeight: 160)
                
                Spacer()
                
                // Page indicators with navigation buttons
                HStack {
                    if currentPage > 0 {
                        Button(action: {
                            withAnimation {
                                currentPage -= 1
                            }
                        }) {
                            Label("Previous", systemImage: "chevron.left")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity)
                    }
                    
                    Spacer()
                    
                    // Page indicators
                    HStack(spacing: 12) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? pages[index].color : Color.white.opacity(0.3))
                                .frame(width: 12, height: 12)
                                .scaleEffect(currentPage == index ? 1.2 : 1.0)
                                .shadow(color: currentPage == index ? pages[index].color.opacity(0.7) : .clear, radius: 5)
                                .animation(.spring(), value: currentPage)
                                .onTapGesture {
                                    withAnimation {
                                        currentPage = index
                                    }
                                }
                        }
                    }
                    
                    Spacer()
                    
                    // Next/Complete button
                    Button(action: {
                        if currentPage < pages.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            withAnimation {
                                onComplete()
                            }
                        }
                    }) {
                        Label(currentPage < pages.count - 1 ? "Next" : "Begin Experience", 
                              systemImage: currentPage < pages.count - 1 ? "chevron.right" : "sparkles")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding(.horizontal, currentPage < pages.count - 1 ? 20 : 25)
                            .padding(.vertical, 12)
                            .background(currentPage < pages.count - 1 ? Color.white : pages[currentPage].color)
                            .clipShape(Capsule())
                            .shadow(color: currentPage < pages.count - 1 ? .white.opacity(0.3) : pages[currentPage].color.opacity(0.5), radius: 8)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.defaultAction)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
                .frame(maxWidth: 600)
            }
            .padding()
        }
        .onAppear {
            // Show continue button after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    showContinueButton = true
                }
            }
        }
    }
    
    // Remove all the 3D model helper functions since they're no longer used
}

struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
    let color: Color
    let modelName: String // We keep this for data structure compatibility, even though we don't use 3D models
}

#Preview {
    OnboardingView(onComplete: {})
} 