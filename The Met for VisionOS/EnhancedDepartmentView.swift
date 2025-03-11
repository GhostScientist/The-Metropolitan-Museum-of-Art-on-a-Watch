//
//  EnhancedDepartmentView.swift
//  The Met for VisionOS
//
//  Created by Dakota Kim on 1/20/25.
//

import SwiftUI
import RealityKit
import TheMetUtilities

struct EnhancedDepartmentView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismiss) private var dismiss
    
    let department: Department
    
    @State private var objects: [ObjectDetails] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var allObjectIDs: [Int] = []
    @State private var currentIndex = 0
    @State private var selectedViewMode: ViewMode = .grid
    @State private var selectedSortOption: SortOption = .default
    @State private var hoveredObjectID: Int?
    
    private let metMuseumClient = MetMuseumClient()
    private let pageSize = 20
    
    enum ViewMode: String, CaseIterable, Identifiable {
        case grid = "Grid"
        case carousel = "Carousel"
        case wall = "Gallery Wall"
        
        var id: String { self.rawValue }
        
        var iconName: String {
            switch self {
            case .grid: return "square.grid.2x2"
            case .carousel: return "rectangle.stack"
            case .wall: return "rectangle.3.group"
            }
        }
    }
    
    enum SortOption: String, CaseIterable, Identifiable {
        case `default` = "Default"
        case dateAsc = "Date (Oldest)"
        case dateDesc = "Date (Newest)"
        case titleAsc = "Title (A-Z)"
        case titleDesc = "Title (Z-A)"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.05)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text(department.displayName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("\(allObjectIDs.count) artworks")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top)
                
                // Search and filter controls
                HStack {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search \(department.displayName)...", text: $searchText)
                            .textFieldStyle(.plain)
                            .submitLabel(.search)
                            .onSubmit {
                                resetAndSearch()
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                if isSearching {
                                    resetAndSearch()
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(10)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    // View mode picker
                    Picker("View", selection: $selectedViewMode) {
                        ForEach(ViewMode.allCases) { mode in
                            Label(mode.rawValue, systemImage: mode.iconName)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 300)
                    
                    // Sort options
                    Menu {
                        ForEach(SortOption.allCases) { option in
                            Button(action: {
                                selectedSortOption = option
                                sortObjects()
                            }) {
                                Label(option.rawValue, systemImage: selectedSortOption == option ? "checkmark" : "")
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                    .menuStyle(.button)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                
                // Main content
                Group {
                    if isLoading && objects.isEmpty {
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Loading artworks...")
                                .font(.headline)
                                .padding()
                        }
                    } else if let error = errorMessage {
                        VStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.yellow)
                                .padding()
                            
                            Text(error)
                                .font(.headline)
                            
                            Button("Try Again") {
                                loadInitialContent()
                            }
                            .buttonStyle(.bordered)
                            .padding()
                        }
                    } else if objects.isEmpty {
                        VStack {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                                .padding()
                            
                            Text("No artworks found")
                                .font(.headline)
                            
                            if isSearching {
                                Button("Clear Search") {
                                    searchText = ""
                                    resetAndSearch()
                                }
                                .buttonStyle(.bordered)
                                .padding()
                            }
                        }
                    } else {
                        // Content based on selected view mode
                        switch selectedViewMode {
                        case .grid:
                            ArtworkGridView(
                                objects: objects,
                                hoveredObjectID: $hoveredObjectID,
                                onObjectTap: { object in
                                    openWindow(id: "artwork-detail", value: object)
                                },
                                onAppear: { object in
                                    if objects.count > 0 && object.objectID == objects.last?.objectID && currentIndex < allObjectIDs.count {
                                        Task {
                                            await loadMoreContent()
                                        }
                                    }
                                }
                            )
                            
                        case .carousel:
                            ArtworkCarouselView(
                                objects: objects,
                                hoveredObjectID: $hoveredObjectID,
                                onObjectTap: { object in
                                    openWindow(id: "artwork-detail", value: object)
                                }
                            )
                            
                        case .wall:
                            ArtworkWallView(
                                objects: objects,
                                hoveredObjectID: $hoveredObjectID,
                                onObjectTap: { object in
                                    openWindow(id: "artwork-detail", value: object)
                                }
                            )
                        }
                    }
                }
                
                // Loading indicator at bottom
                if isLoading && !objects.isEmpty {
                    ProgressView()
                        .padding()
                }
            }
            
            // Close button
            VStack {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding()
                    
                    Spacer()
                }
                Spacer()
            }
        }
        .onAppear {
            loadInitialContent()
        }
    }
    
    private func resetAndSearch() {
        Task {
            await MainActor.run {
                objects = []
                currentIndex = 0
                allObjectIDs = []
                isLoading = true
                isSearching = !searchText.isEmpty
            }
            
            if searchText.isEmpty {
                loadInitialContent()
            } else {
                await searchObjects()
            }
        }
    }
    
    private func searchObjects() async {
        do {
            let searchResult = try await metMuseumClient.searchDepartmentForObjectsBySearchTerm(
                searchTerm: searchText,
                departmentId: department.departmentId
            )
            
            await MainActor.run {
                allObjectIDs = searchResult.objectIDs
                isLoading = false
            }
            
            await loadMoreContent()
        } catch {
            await MainActor.run {
                errorMessage = "Failed to search"
                isLoading = false
                isSearching = false
            }
        }
    }
    
    private func loadMoreContent() async {
        await MainActor.run {
            guard !isLoading, currentIndex < allObjectIDs.count else {
                return
            }
            isLoading = true
        }
        
        let endIndex = await MainActor.run {
            let end = min(currentIndex + pageSize, allObjectIDs.count)
            let ids = Array(allObjectIDs[currentIndex..<end])
            return end
        }
        
        let idsToFetch = await MainActor.run {
            Array(allObjectIDs[currentIndex..<endIndex])
        }
        
        do {
            let newObjects = try await withThrowingTaskGroup(of: ObjectDetails.self) { group in
                for id in idsToFetch {
                    group.addTask {
                        if let cachedObject = await ObjectCache.shared.object(for: id) {
                            return cachedObject
                        }
                        let fetchedObject = try await metMuseumClient.fetchObjectDetails(objectID: id)
                        await ObjectCache.shared.cache(fetchedObject)
                        return fetchedObject
                    }
                }
                
                var fetchedObjects: [ObjectDetails] = []
                for try await object in group {
                    fetchedObjects.append(object)
                }
                return fetchedObjects.sorted { $0.objectID < $1.objectID }
            }
            
            await MainActor.run {
                objects.append(contentsOf: newObjects)
                currentIndex = endIndex
                isLoading = false
                sortObjects()
            }
        } catch {
            await MainActor.run {
                if error.isInternetConnectionError {
                    errorMessage = "No network connection - try again when reconnected."
                } else {
                    errorMessage = "Failed to fetch objects"
                }
                isLoading = false
            }
        }
    }
    
    private func loadInitialContent() {
        Task {
            do {
                if isSearching && searchText != "" {
                    let searchResult = try await metMuseumClient.searchDepartmentForObjectsBySearchTerm(
                        searchTerm: searchText,
                        departmentId: department.departmentId
                    )
                    allObjectIDs = searchResult.objectIDs
                } else {
                    let result = try await metMuseumClient.fetchObjects(departmentId: department.departmentId)
                    allObjectIDs = Array(result.allAsInt)
                }
                await loadMoreContent()
            } catch {
                errorMessage = "Failed to load initial content"
            }
        }
    }
    
    private func sortObjects() {
        switch selectedSortOption {
        case .default:
            objects.sort { $0.objectID < $1.objectID }
        case .dateAsc:
            objects.sort { $0.objectDate < $1.objectDate }
        case .dateDesc:
            objects.sort { $0.objectDate > $1.objectDate }
        case .titleAsc:
            objects.sort { $0.title < $1.title }
        case .titleDesc:
            objects.sort { $0.title > $1.title }
        }
    }
}

// MARK: - Artwork Grid View
struct ArtworkGridView: View {
    let objects: [ObjectDetails]
    @Binding var hoveredObjectID: Int?
    let onObjectTap: (ObjectDetails) -> Void
    let onAppear: (ObjectDetails) -> Void
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200, maximum: 300), spacing: 20)], spacing: 20) {
                ForEach(objects) { object in
                    ArtworkGridItem(object: object, isHovered: hoveredObjectID == object.objectID)
                        .onTapGesture {
                            onObjectTap(object)
                        }
                        .onHover { isHovered in
                            hoveredObjectID = isHovered ? object.objectID : nil
                        }
                        .onAppear {
                            onAppear(object)
                        }
                }
            }
            .padding()
        }
    }
}

struct ArtworkGridItem: View {
    let object: ObjectDetails
    let isHovered: Bool
    
    var body: some View {
        VStack {
            if !object.primaryImage.isEmpty {
                AsyncImage(url: URL(string: object.primaryImage)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay {
                            ProgressView()
                        }
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isHovered ? Color.white : Color.clear, lineWidth: 2)
                )
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isHovered ? Color.white : Color.clear, lineWidth: 2)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(object.title)
                    .font(.headline)
                    .lineLimit(2)
                
                if !object.artistDisplayName.isEmpty {
                    Text(object.artistDisplayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Text(object.objectDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(radius: isHovered ? 10 : 5)
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isHovered)
    }
}

// MARK: - Artwork Carousel View
struct ArtworkCarouselView: View {
    let objects: [ObjectDetails]
    @Binding var hoveredObjectID: Int?
    let onObjectTap: (ObjectDetails) -> Void
    
    @State private var currentIndex: Int = 0
    
    var body: some View {
        VStack {
            // Carousel
            TabView(selection: $currentIndex) {
                ForEach(Array(objects.enumerated()), id: \.element.id) { index, object in
                    ArtworkCarouselItem(
                        object: object,
                        isHovered: hoveredObjectID == object.objectID
                    )
                    .tag(index)
                    .onTapGesture {
                        onObjectTap(object)
                    }
                    .onHover { isHovered in
                        hoveredObjectID = isHovered ? object.objectID : nil
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 500)
            
            // Carousel controls
            HStack(spacing: 20) {
                Button(action: {
                    withAnimation {
                        currentIndex = max(currentIndex - 1, 0)
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .disabled(currentIndex == 0)
                
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<min(objects.count, 7), id: \.self) { index in
                        Circle()
                            .fill(currentIndex == index ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                    
                    if objects.count > 7 {
                        Text("...")
                            .foregroundColor(.secondary)
                    }
                }
                
                Button(action: {
                    withAnimation {
                        currentIndex = min(currentIndex + 1, objects.count - 1)
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .disabled(currentIndex == objects.count - 1)
            }
            .padding(.top, 20)
        }
    }
}

struct ArtworkCarouselItem: View {
    let object: ObjectDetails
    let isHovered: Bool
    
    var body: some View {
        VStack {
            if !object.primaryImage.isEmpty {
                AsyncImage(url: URL(string: object.primaryImage)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay {
                            ProgressView()
                        }
                }
                .frame(maxHeight: 400)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(isHovered ? Color.white : Color.clear, lineWidth: 2)
                )
                .shadow(radius: 10)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .overlay {
                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                    }
                    .shadow(radius: 10)
            }
            
            VStack(spacing: 8) {
                Text(object.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                if !object.artistDisplayName.isEmpty {
                    Text(object.artistDisplayName)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                
                Text(object.objectDate)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)
        }
        .padding(.horizontal, 40)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isHovered)
    }
}

// MARK: - Artwork Wall View
struct ArtworkWallView: View {
    let objects: [ObjectDetails]
    @Binding var hoveredObjectID: Int?
    let onObjectTap: (ObjectDetails) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .bottom, spacing: 20) {
                ForEach(objects) { object in
                    ArtworkWallItem(
                        object: object,
                        isHovered: hoveredObjectID == object.objectID
                    )
                    .onTapGesture {
                        onObjectTap(object)
                    }
                    .onHover { isHovered in
                        hoveredObjectID = isHovered ? object.objectID : nil
                    }
                }
            }
            .padding(40)
        }
        .frame(maxHeight: .infinity)
    }
}

struct ArtworkWallItem: View {
    let object: ObjectDetails
    let isHovered: Bool
    
    // Random height for visual interest
    private let heightMultiplier: CGFloat = CGFloat.random(in: 0.7...1.3)
    
    var body: some View {
        VStack(spacing: 8) {
            if !object.primaryImage.isEmpty {
                AsyncImage(url: URL(string: object.primaryImage)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay {
                            ProgressView()
                        }
                }
                .frame(width: 200, height: 250 * heightMultiplier)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.white, lineWidth: 4)
                )
                .shadow(radius: isHovered ? 15 : 5)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 200, height: 250 * heightMultiplier)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .overlay {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.white, lineWidth: 4)
                    )
                    .shadow(radius: isHovered ? 15 : 5)
            }
            
            if isHovered {
                VStack(spacing: 4) {
                    Text(object.title)
                        .font(.caption)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    if !object.artistDisplayName.isEmpty {
                        Text(object.artistDisplayName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 200)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .scaleEffect(isHovered ? 1.1 : 1.0)
        .zIndex(isHovered ? 1 : 0)
        .animation(.spring(response: 0.3), value: isHovered)
    }
}

#Preview {
    EnhancedDepartmentView(department: Department(departmentId: 1, displayName: "American Decorative Arts"))
        .environment(AppModel())
} 