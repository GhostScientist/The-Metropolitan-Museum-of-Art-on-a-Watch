//
//  MetGalleryImmersiveView.swift
//  The Met for VisionOS
//
//  Created by Dakota Kim on 1/20/25.
//

import SwiftUI
// Remove RealityKit since we're not using 3D models anymore
// import RealityKit
import TheMetUtilities

struct MetGalleryImmersiveView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismiss) private var dismiss
    
    @State private var featuredArtworks: [ObjectDetails] = []
    @State private var selectedArtwork: ObjectDetails?
    @State private var isLoading = true
    @State private var showOptions = false
    @State private var galleryStyle: GalleryStyle = .modern
    @State private var lightingStyle: LightingStyle = .natural
    
    private let metMuseumClient = MetMuseumClient()
    
    enum GalleryStyle: String, CaseIterable, Identifiable {
        case modern = "Modern"
        case classical = "Classical"
        case minimalist = "Minimalist"
        
        var id: String { self.rawValue }
    }
    
    enum LightingStyle: String, CaseIterable, Identifiable {
        case natural = "Natural"
        case warm = "Warm"
        case dramatic = "Dramatic"
        case cool = "Cool"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        ZStack {
            // Background based on gallery style
            backgroundForStyle(galleryStyle)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Met Gallery Experience")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(textColorForStyle(galleryStyle))
                    
                    Spacer()
                    
                    Button {
                        showOptions.toggle()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(textColorForStyle(galleryStyle))
                }
                .padding()
                
                if isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading artworks...")
                        .font(.headline)
                        .foregroundStyle(textColorForStyle(galleryStyle))
                    Spacer()
                } else if featuredArtworks.isEmpty {
                    Spacer()
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 70))
                        .foregroundStyle(textColorForStyle(galleryStyle))
                    Text("No artworks to display")
                        .font(.headline)
                        .foregroundStyle(textColorForStyle(galleryStyle))
                    
                    Button("Load Featured Artworks") {
                        loadFeaturedArtworks()
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                } else {
                    // Gallery Grid
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 20)], spacing: 20) {
                            ForEach(featuredArtworks, id: \.objectID) { artwork in
                                ArtworkCard(artwork: artwork, galleryStyle: galleryStyle, lightingStyle: lightingStyle)
                                    .onTapGesture {
                                        selectedArtwork = artwork
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .sheet(item: $selectedArtwork) { artwork in
                EnhancedArtworkDetailView(objectDetails: artwork)
                    .environment(appModel)
            }
            .sheet(isPresented: $showOptions) {
                GalleryOptionsView(
                    galleryStyle: $galleryStyle,
                    lightingStyle: $lightingStyle
                )
            }
        }
        .onAppear {
            loadFeaturedArtworks()
            
            // Set up notification observer for window closing
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("CloseGalleryWindow"),
                object: nil,
                queue: .main) { _ in
                dismiss()
            }
        }
        .onDisappear {
            // Remove notification observer
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name("CloseGalleryWindow"),
                object: nil
            )
        }
    }
    
    private func loadFeaturedArtworks() {
        isLoading = true
        
        Task {
            do {
                // First get the department
                let departments = try await metMuseumClient.fetchDepartments().departments
                
                if let randomDepartment = departments.randomElement() {
                    // Instead of using fetchDepartmentObjects, use searchObjects with the department name
                    let departmentName = randomDepartment.displayName
                    let searchResults = try await metMuseumClient.searchObjects(query: SearchQuery(query: departmentName))
                    
                    // Select a random subset from the search results
                    let selectedObjectIDs = Array(searchResults.objectIDs.prefix(15).shuffled())
                    
                    // Fetch details for each object
                    var loadedArtworks: [ObjectDetails] = []
                    for objectID in selectedObjectIDs {
                        if let details = try? await metMuseumClient.fetchObjectDetails(objectID: objectID),
                           details.primaryImage.isEmpty == false {
                            loadedArtworks.append(details)
                            if loadedArtworks.count >= 6 {
                                break
                            }
                        }
                    }
                    
                    await MainActor.run {
                        featuredArtworks = loadedArtworks
                        isLoading = false
                    }
                }
            } catch {
                print("Error loading featured artworks: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    
    private func backgroundForStyle(_ style: GalleryStyle) -> some View {
        Group {
            switch style {
            case .modern:
                Color(white: 0.98)
            case .classical:
                Color(red: 0.93, green: 0.9, blue: 0.85)
            case .minimalist:
                Color.black
            }
        }
    }
    
    private func textColorForStyle(_ style: GalleryStyle) -> Color {
        style == .minimalist ? .white : .black
    }
}

struct ArtworkCard: View {
    let artwork: ObjectDetails
    let galleryStyle: MetGalleryImmersiveView.GalleryStyle
    let lightingStyle: MetGalleryImmersiveView.LightingStyle
    
    var body: some View {
        VStack {
            AsyncImage(url: URL(string: artwork.primaryImage)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(galleryStyle == .modern ? 8 : 0)
                        .overlay(
                            RoundedRectangle(cornerRadius: galleryStyle == .modern ? 8 : 0)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: shadowColorForLighting(lightingStyle), 
                               radius: shadowRadiusForStyle(galleryStyle), 
                               x: 0, y: 2)
                case .failure:
                    Image(systemName: "photo.fill")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(height: 200)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(artwork.title)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundStyle(textColorForStyle(galleryStyle))
                
                if !artwork.artistDisplayName.isEmpty {
                    Text(artwork.artistDisplayName)
                        .font(.subheadline)
                        .foregroundStyle(textColorForStyle(galleryStyle).opacity(0.8))
                }
                
                Text(artwork.objectDate)
                    .font(.caption)
                    .foregroundStyle(textColorForStyle(galleryStyle).opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .padding(10)
        .background(backgroundForCardStyle(galleryStyle))
        .cornerRadius(galleryStyle == .minimalist ? 0 : 10)
        .shadow(color: shadowColorForLighting(lightingStyle).opacity(0.2), 
                radius: shadowRadiusForStyle(galleryStyle) * 2, 
                x: 0, y: 4)
    }
    
    private func backgroundForCardStyle(_ style: MetGalleryImmersiveView.GalleryStyle) -> some View {
        Group {
            switch style {
            case .modern:
                Color.white
            case .classical:
                Color(red: 0.98, green: 0.95, blue: 0.9)
            case .minimalist:
                Color(white: 0.1)
            }
        }
    }
    
    private func shadowColorForLighting(_ style: MetGalleryImmersiveView.LightingStyle) -> Color {
        switch style {
        case .natural:
            return Color.black
        case .warm:
            return Color(red: 0.7, green: 0.3, blue: 0.1)
        case .dramatic:
            return Color(red: 0.3, green: 0.1, blue: 0.3)
        case .cool:
            return Color(red: 0.1, green: 0.3, blue: 0.7)
        }
    }
    
    private func shadowRadiusForStyle(_ style: MetGalleryImmersiveView.GalleryStyle) -> CGFloat {
        switch style {
        case .modern:
            return 5
        case .classical:
            return 3
        case .minimalist:
            return 8
        }
    }
    
    private func textColorForStyle(_ style: MetGalleryImmersiveView.GalleryStyle) -> Color {
        style == .minimalist ? .white : .black
    }
}

struct GalleryOptionsView: View {
    @Binding var galleryStyle: MetGalleryImmersiveView.GalleryStyle
    @Binding var lightingStyle: MetGalleryImmersiveView.LightingStyle
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Gallery Settings")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading) {
                Text("Gallery Style:")
                    .font(.headline)
                
                Picker("Gallery Style", selection: $galleryStyle) {
                    ForEach(MetGalleryImmersiveView.GalleryStyle.allCases) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            VStack(alignment: .leading) {
                Text("Lighting:")
                    .font(.headline)
                
                Picker("Lighting Style", selection: $lightingStyle) {
                    ForEach(MetGalleryImmersiveView.LightingStyle.allCases) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .padding()
        .frame(width: 400)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .padding()
    }
}

#Preview {
    MetGalleryImmersiveView()
        .environment(AppModel())
} 
