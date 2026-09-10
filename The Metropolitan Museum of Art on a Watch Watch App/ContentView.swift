import SwiftUI
import UIKit

/// The gallery walk. A fixed frame on the wall; turning the Digital Crown
/// swaps the artwork inside it and the placard beneath it, one department
/// at a time. Tapping the artwork walks into that department.
struct ContentView: View {
    @State private var departments: [Department] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedDepartmentID: Int?
    @State private var backdrop: UIImage?
    @State private var path = NavigationPath()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    private let metMuseumClient = MetMuseumClient()

    private var selectedDepartment: Department? {
        departments.first { $0.id == selectedDepartmentID } ?? departments.first
    }

    private var selectedIndex: Int? {
        guard let selectedDepartment else { return nil }
        return departments.firstIndex(of: selectedDepartment)
    }

    var body: some View {
        ZStack {
            if hasCompletedOnboarding {
                galleries
                    .transition(.opacity)
            } else {
                OnboardingView {
                    withAnimation(.easeInOut(duration: 0.7)) {
                        hasCompletedOnboarding = true
                    }
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            if departments.isEmpty { fetchDepartments() }
        }
        .onChange(of: selectedDepartmentID, initial: true) { _, _ in
            updateBackdrop()
        }
        .onOpenURL { url in
            handleDeepLink(url)
        }
    }

    private var galleries: some View {
        NavigationStack(path: $path) {
            Group {
                if isLoading {
                    ProgressView("Loading")
                } else if let errorMessage {
                    ContentUnavailableView {
                        Label("The doors are closed", systemImage: "building.columns")
                    } description: {
                        Text(errorMessage)
                    } actions: {
                        Button("Try Again") { fetchDepartments() }
                    }
                } else {
                    galleryWalk
                }
            }
            .navigationDestination(for: Department.self) { department in
                DepartmentGalleryView(department: department)
            }
            .navigationDestination(for: ObjectDetails.self) { object in
                ObjectDetailView(objectDetails: object)
            }
            .navigationDestination(for: SearchScope.self) { scope in
                ArtworkSearchView(scope: scope)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(value: SearchScope.collection) {
                        Image(systemName: "magnifyingglass")
                    }
                }
            }
            .containerBackground(for: .navigation) {
                AmbientBackdrop(image: backdrop)
            }
        }
    }

    // MARK: - Gallery walk

    private var galleryWalk: some View {
        VStack(spacing: 6) {
            GalleryFrame {
                GeometryReader { proxy in
                    ScrollView(.vertical) {
                        LazyVStack(spacing: 0) {
                            ForEach(departments) { department in
                                NavigationLink(value: department) {
                                    DepartmentArtwork(department: department)
                                        .frame(width: proxy.size.width, height: proxy.size.height)
                                        .clipped()
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned)
                    .scrollPosition(id: $selectedDepartmentID)
                    .scrollIndicators(.hidden)
                    .contentMargins(0, for: .scrollContent)
                }
            }
            .frame(maxHeight: .infinity)

            placard
        }
        .padding(.horizontal, 2)
    }

    private var placard: some View {
        VStack(spacing: 1) {
            Text(selectedDepartment?.displayName ?? " ")
                .font(.system(.footnote, design: .serif, weight: .semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)

            if let selectedIndex {
                Text("\(selectedIndex + 1) of \(departments.count)")
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 40)
        .animation(.easeInOut(duration: 0.2), value: selectedDepartmentID)
    }

    // MARK: - Data

    private func fetchDepartments() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                departments = try await metMuseumClient.fetchDepartments().departments
                selectedDepartmentID = departments.first?.id
            } catch {
                if error.isInternetConnectionError {
                    errorMessage = "You're offline. Reconnect to browse the collection."
                } else {
                    errorMessage = "The collection couldn't be loaded."
                }
            }
            isLoading = false
        }
    }

    /// The backdrop is a tiny thumbnail blurred up to full screen, which is
    /// far cheaper on the watch's GPU than blurring the full image.
    private func updateBackdrop() {
        guard let selectedDepartment else {
            backdrop = nil
            return
        }
        let assetName = selectedDepartment.imageAssetName
        Task {
            backdrop = await ImageLoader.shared.thumbnail(named: assetName, maxPixelSize: 48)
        }
    }

    /// `tinymet://object/<id>`, sent by the widget when a complication is tapped.
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "tinymet",
              url.host() == "object",
              let objectID = Int(url.lastPathComponent)
        else { return }

        Task {
            guard let object = try? await metMuseumClient.fetchObjectDetails(objectID: objectID) else { return }
            hasCompletedOnboarding = true
            var newPath = NavigationPath()
            if let department = departments.first(where: { $0.displayName == object.department }) {
                newPath.append(department)
            }
            newPath.append(object)
            path = newPath
        }
    }
}

/// A department's hero artwork, filling whatever frame it is hung in.
struct DepartmentArtwork: View {
    let department: Department

    var body: some View {
        if UIImage(named: department.imageAssetName) != nil {
            Image(department.imageAssetName)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.24, green: 0.20, blue: 0.30), .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                Image(systemName: "paintpalette")
                    .font(.largeTitle)
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
    }
}

/// A dimmed, blurred wash of the current artwork behind the whole screen.
struct AmbientBackdrop: View {
    let image: UIImage?

    var body: some View {
        ZStack {
            Color.black
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 24)
                    .saturation(1.3)
                    .opacity(0.45)
                    .id(image)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: image)
        .ignoresSafeArea()
    }
}
