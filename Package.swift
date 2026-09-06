// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TinyMetCore",
    platforms: [.macOS(.v14), .watchOS(.v10)],
    products: [.library(name: "TinyMetCore", targets: ["TinyMetCore"])],
    targets: [
        .target(
            name: "TinyMetCore",
            path: "The Metropolitan Museum of Art on a Watch Watch App",
            exclude: [
                "Assets.xcassets", "Preview Content", "ContentView.swift", "DepartmentListView.swift",
                "ImageInspectView.swift", "ObjectDetailView.swift", "ObjectInfoSection.swift",
                "The_Metropolitan_Museum_of_Art_on_a_WatchApp.swift", "NetworkError.swift",
                "Helpers/OnFirstAppearModifier.swift", "Types/Object.swift",
                "ArtworkImageView.swift", "FavoritesView.swift"
            ],
            sources: [
                "API/TheMetMuseumAPI.swift", "Types/Department.swift", "Types/Search.swift",
                "Types/Objects.swift", "Helpers/CachedObjectDetails.swift", "Models/DepartmentBrowser.swift",
                "Helpers/FavoritesStore.swift", "Helpers/ArtworkImageCache.swift"
            ]
        ),
        .testTarget(name: "TinyMetCoreTests", dependencies: ["TinyMetCore"], path: "Tests")
    ]
)
