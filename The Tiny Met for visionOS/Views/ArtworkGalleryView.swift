//
//  ArtworkGalleryView.swift
//  The Tiny Met for visionOS
//
//  Created by Dakota Kim on 8/18/25.
//

import SwiftUI
import RealityKit

struct ArtworkGalleryView: View {
    let department: Department
    
    @State private var allObjectIDs: [Int] = []
    @State private var filteredObjectIDs: [Int] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var searchResults: [Int] = []
    @State private var isSearching = false
    
    private let metMuseumClient = MetMuseumClient()
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    
                    TextField("Search \(department.displayName)...", text: $searchText)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            performSearch()
                        }
                    
                    if !searchText.isEmpty {
                        Button("Clear") {
                            searchText = ""
                            filteredObjectIDs = allObjectIDs
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.regularMaterial, in: Capsule())
                .shadow(radius: 2)
                
                if isSearching {
                    WaveLoadingView()
                }
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 20)
            .background(.ultraThinMaterial, in: Rectangle())
            
            Group {
                if isLoading && allObjectIDs.isEmpty {
                    EnhancedLoadingView(message: "Loading \(department.displayName) Collection...")
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                    
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.orange)
                        
                        Text(errorMessage)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        
                        Button("Retry") {
                            loadInitialContent()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 30),
                            GridItem(.flexible(), spacing: 30),
                            GridItem(.flexible(), spacing: 30)
                        ], spacing: 30) {
                            ForEach(filteredObjectIDs, id: \.self) { objectID in
                                LazyArtworkCard(objectID: objectID)
                            }
                        }
                        .padding(60)
                    }
                    .refreshable {
                        loadInitialContent()
                    }
                }
            }
        }
        .navigationTitle(department.displayName)
        .onAppear {
            if allObjectIDs.isEmpty {
                loadInitialContent()
            }
        }
        .onChange(of: searchText) { _, newValue in
            if newValue.isEmpty {
                filteredObjectIDs = allObjectIDs
            } else {
                // Filter by simple text matching for now
                // In a real app, you'd want more sophisticated search
                filteredObjectIDs = allObjectIDs.shuffled().prefix(20).map { $0 }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    openWindow(id: "VolumeGallery", value: department.departmentId)
                } label: {
                    Label("Open in Volume", systemImage: "cube.fill")
                }
            }
        }
    }
    
    private func loadInitialContent() {
        Task {
            await MainActor.run {
                allObjectIDs = []
                filteredObjectIDs = []
                isLoading = true
                errorMessage = nil
            }
            
            do {
                let result = try await metMuseumClient.fetchObjects(departmentId: department.departmentId)
                await MainActor.run {
                    allObjectIDs = Array(result.allAsInt.prefix(50)) // Increased limit for better variety
                    filteredObjectIDs = allObjectIDs
                    isLoading = false
                    print("✅ Loaded \(allObjectIDs.count) object IDs for department \(department.departmentId)")
                }
            } catch {
                await MainActor.run {
                    print("❌ Error loading objects: \(error)")
                    if error.isInternetConnectionError {
                        errorMessage = "No internet connection"
                    } else {
                        errorMessage = "Failed to load collection: \(error.localizedDescription)"
                    }
                    isLoading = false
                }
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else {
            filteredObjectIDs = allObjectIDs
            return
        }
        
        Task {
            await MainActor.run {
                isSearching = true
            }
            
            do {
                // Perform search within department
                let searchResult = try await metMuseumClient.searchInDepartment(
                    query: searchText,
                    departmentId: department.departmentId
                )
                
                await MainActor.run {
                    filteredObjectIDs = Array(searchResult.objectIDs.prefix(30))
                    isSearching = false
                    print("🔍 Search found \(filteredObjectIDs.count) results for '\(searchText)'")
                }
            } catch {
                await MainActor.run {
                    // Fallback to simple filtering
                    filteredObjectIDs = allObjectIDs.shuffled().prefix(20).map { $0 }
                    isSearching = false
                    print("⚠️ Search failed, showing random results")
                }
            }
        }
    }
}

struct ArtworkCardView: View {
    let artwork: ObjectDetails
    @Environment(\.openWindow) private var openWindow
    @State private var isHovered = false
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0
    @State private var showParticles = false
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                scale = 0.95
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    scale = 1.0
                }
                openWindow(id: "ArtworkDetail", value: artwork.objectID)
            }
        } label: {
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
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.quaternary)
                            .frame(height: 180)
                            .overlay {
                                VStack(spacing: 8) {
                                    Image(systemName: "photo")
                                        .font(.system(size: 30))
                                        .foregroundStyle(.secondary)
                                    Text("Loading...")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
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
            .buttonStyle(.plain)
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
}

struct LoadMoreView: View {
    var body: some View {
        VStack {
            WaveLoadingView()
            Text("Loading more masterpieces...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(height: 100)
        .padding()
    }
    
    #Preview {
        ArtworkGalleryView(department: Department(departmentId: 11, displayName: "European Paintings"))
    }
}
