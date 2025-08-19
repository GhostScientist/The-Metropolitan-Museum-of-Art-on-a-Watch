//
//  ArtworkDetailView.swift
//  The Tiny Met for visionOS
//
//  Created by Dakota Kim on 8/18/25.
//

import SwiftUI

struct ArtworkDetailView: View {
    let objectID: Int
    
    @State private var artwork: ObjectDetails?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    private let metMuseumClient = MetMuseumClient()
    
    var body: some View {
        Group {
            if isLoading {
                VStack(spacing: 15) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading artwork details...")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            } else if let errorMessage = errorMessage {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundStyle(.orange)
                    
                    Text(errorMessage)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Button("Retry") {
                        loadArtwork()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            } else if let artwork = artwork {
                ArtworkDetailContent(artwork: artwork)
            } else {
                Text("Artwork not found")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 600, maxWidth: 800, minHeight: 400, maxHeight: 900)
        .task {
            loadArtwork()
        }
    }
    
    private func loadArtwork() {
        Task {
            await MainActor.run {
                isLoading = true
                errorMessage = nil
            }
            
            do {
                // Check cache first
                if let cachedArtwork = await ObjectCache.shared.object(for: objectID) {
                    await MainActor.run {
                        self.artwork = cachedArtwork
                        self.isLoading = false
                    }
                    return
                }
                
                // Fetch from API
                let fetchedArtwork = try await metMuseumClient.fetchObjectDetails(objectID: objectID)
                await ObjectCache.shared.cache(fetchedArtwork)
                
                await MainActor.run {
                    self.artwork = fetchedArtwork
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    if error.isInternetConnectionError {
                        self.errorMessage = "No internet connection"
                    } else {
                        self.errorMessage = "Failed to load artwork"
                    }
                    self.isLoading = false
                }
            }
        }
    }
}

struct ArtworkDetailContent: View {
    let artwork: ObjectDetails
    @State private var imageScale: CGFloat = 1.0
    @State private var imageOffset: CGSize = .zero
    @State private var showImageFullscreen = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Main artwork image with zoom and gestures
                if !artwork.primaryImage.isEmpty {
                    ZStack {
                        AsyncImage(url: URL(string: artwork.primaryImage)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 400)
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                .shadow(
                                    color: .black.opacity(0.2),
                                    radius: imageScale > 1.0 ? 20 : 10,
                                    x: 0,
                                    y: imageScale > 1.0 ? 10 : 5
                                )
                                .scaleEffect(imageScale)
                                .offset(imageOffset)
                                .gesture(
                                    SimultaneousGesture(
                                        MagnificationGesture()
                                            .onChanged { value in
                                                withAnimation(.interactiveSpring()) {
                                                    imageScale = max(1.0, min(3.0, value))
                                                }
                                            }
                                            .onEnded { _ in
                                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                    if imageScale < 1.2 {
                                                        imageScale = 1.0
                                                        imageOffset = .zero
                                                    }
                                                }
                                            },
                                        DragGesture()
                                            .onChanged { value in
                                                if imageScale > 1.0 {
                                                    imageOffset = value.translation
                                                }
                                            }
                                            .onEnded { _ in
                                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                    if imageScale <= 1.0 {
                                                        imageOffset = .zero
                                                    }
                                                }
                                            }
                                    )
                                )
                                .onTapGesture(count: 2) {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                        if imageScale > 1.0 {
                                            imageScale = 1.0
                                            imageOffset = .zero
                                        } else {
                                            imageScale = 2.0
                                        }
                                    }
                                }
                                .onTapGesture {
                                    showImageFullscreen = true
                                }
                        } placeholder: {
                            ShimmerLoadingView(width: 400, height: 300)
                        }
                        
                        // Zoom instructions overlay
                        if imageScale == 1.0 {
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    VStack(spacing: 4) {
                                        Image(systemName: "hand.tap.fill")
                                            .font(.caption)
                                        Text("Tap to expand")
                                            .font(.caption2)
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.black.opacity(0.6), in: Capsule())
                                    .padding()
                                }
                            }
                        }
                    }
                } else {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(.quaternary)
                        .frame(height: 250)
                        .overlay {
                            VStack(spacing: 10) {
                                Image(systemName: "photo")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.secondary)
                                Text("No image available")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .shimmer()
                }
                
                // Artwork information
                VStack(alignment: .leading, spacing: 15) {
                    Text(artwork.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.leading)
                    
                    if !artwork.artistDisplayName.isEmpty {
                        Text(artwork.artistDisplayName)
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        
                        if !artwork.artistDisplayBio.isEmpty {
                            Text(artwork.artistDisplayBio)
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    
                    Divider()
                    
                    // Details grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), alignment: .leading),
                        GridItem(.flexible(), alignment: .leading)
                    ], spacing: 15) {
                        if !artwork.objectDate.isEmpty {
                            DetailItem(title: "Date", content: artwork.objectDate)
                        }
                        
                        if !artwork.medium.isEmpty {
                            DetailItem(title: "Medium", content: artwork.medium)
                        }
                        
                        if !artwork.dimensions.isEmpty {
                            DetailItem(title: "Dimensions", content: artwork.dimensions)
                        }
                        
                        DetailItem(title: "Department", content: artwork.department)
                        
                        if !artwork.culture.isEmpty {
                            DetailItem(title: "Culture", content: artwork.culture)
                        }
                        
                        if !artwork.period.isEmpty {
                            DetailItem(title: "Period", content: artwork.period)
                        }
                        
                        if !artwork.geographyType.isEmpty && !artwork.city.isEmpty {
                            DetailItem(title: artwork.geographyType, content: "\(artwork.city), \(artwork.country)")
                        }
                    }
                    
                    Divider()
                    
                    if !artwork.creditLine.isEmpty {
                        DetailItem(title: "Credit Line", content: artwork.creditLine)
                    }
                    
                    // Action buttons
                    HStack(spacing: 15) {
                        if !artwork.objectURL.isEmpty {
                            Link(destination: URL(string: artwork.objectURL)!) {
                                Label("View on Met Website", systemImage: "safari.fill")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        
                        if !artwork.objectURL.isEmpty {
                            ShareLink(items: [URL(string: artwork.objectURL)!]) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.top, 10)
                }
            }
            .padding(25)
        }
        .sheet(isPresented: $showImageFullscreen) {
            if !artwork.primaryImage.isEmpty {
                FullscreenImageView(imageURL: artwork.primaryImage, title: artwork.title)
            }
        }
    }
}

struct DetailItem: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            
            Text(content)
                .font(.body)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ArtworkDetailView(objectID: 45734)
}