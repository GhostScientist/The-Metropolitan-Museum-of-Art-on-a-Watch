//
//  LazyArtworkCard.swift
//  The Tiny Met for visionOS
//
//  Created by Dakota Kim on 8/18/25.
//

import SwiftUI

struct LazyArtworkCard: View {
    let objectID: Int
    @State private var artwork: ObjectDetails?
    @State private var isLoading = true
    @State private var loadError = false
    @Environment(\.openWindow) private var openWindow
    
    private let metMuseumClient = MetMuseumClient()
    
    var body: some View {
        Button {
            if let artwork = artwork {
                openWindow(id: "ArtworkDetail", value: artwork.objectID)
            }
        } label: {
            ZStack {
                if isLoading {
                    LazyLoadingCardView()
                } else if let artwork = artwork {
                    LoadedArtworkCardView(artwork: artwork)
                } else {
                    ErrorCardView()
                }
            }
        }
        .buttonStyle(.plain)
        .floatingPhysics()
        .magneticField()
        .enhancedFeedback(onHover: true, onTap: true)
        .onAppear {
            loadArtwork()
        }
    }
    
    private func loadArtwork() {
        Task {
            do {
                // Check cache first
                if let cachedArtwork = await ObjectCache.shared.object(for: objectID) {
                    await MainActor.run {
                        self.artwork = cachedArtwork
                        self.isLoading = false
                    }
                    return
                }
                
                // Add small delay to stagger loading
                try await Task.sleep(nanoseconds: UInt64.random(in: 100_000_000...500_000_000))
                
                let fetchedArtwork = try await metMuseumClient.fetchObjectDetails(objectID: objectID)
                await ObjectCache.shared.cache(fetchedArtwork)
                
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        self.artwork = fetchedArtwork
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.loadError = true
                    self.isLoading = false
                }
            }
        }
    }
}

struct LazyLoadingCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ShimmerLoadingView(width: .infinity, height: 180)
            
            VStack(alignment: .leading, spacing: 8) {
                ShimmerLoadingView(width: 120, height: 16)
                ShimmerLoadingView(width: 80, height: 12)
                ShimmerLoadingView(width: 60, height: 10)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct LoadedArtworkCardView: View {
    let artwork: ObjectDetails
    @State private var isHovered = false
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0
    @State private var showParticles = false
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                // Artwork image
                AsyncImage(url: URL(string: artwork.primaryImageSmall.isEmpty ? artwork.primaryImage : artwork.primaryImageSmall)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } placeholder: {
                    ShimmerLoadingView(width: .infinity, height: 180)
                }
                
                // Artwork info
                VStack(alignment: .leading, spacing: 8) {
                    Text(artwork.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if !artwork.artistDisplayName.isEmpty {
                        Text(artwork.artistDisplayName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    HStack {
                        if !artwork.objectDate.isEmpty {
                            Text(artwork.objectDate)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        
                        Spacer()
                        
                        if artwork.isHighlight {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(
                color: isHovered ? .blue.opacity(0.3) : .black.opacity(0.1),
                radius: isHovered ? 15 : 8,
                x: 0,
                y: isHovered ? 8 : 4
            )
            
            // Particle effects on hover
            if showParticles {
                FloatingParticleEffect(colors: [.blue, .purple, .cyan, .teal])
                    .allowsHitTesting(false)
            }
        }
        .scaleEffect(scale)
        .rotation3DEffect(
            .degrees(rotation),
            axis: (x: isHovered ? 0.1 : 0, y: isHovered ? 0.1 : 0, z: 0)
        )
        .onHover { hovering in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isHovered = hovering
                scale = hovering ? 1.05 : 1.0
                rotation = hovering ? Double.random(in: -2...2) : 0
                showParticles = hovering
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isHovered)
    }
}

struct ErrorCardView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
            
            Text("Failed to load")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(height: 240)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    LazyArtworkCard(objectID: 45734)
}