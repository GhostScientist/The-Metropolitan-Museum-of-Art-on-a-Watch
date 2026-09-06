import SwiftUI
import ImageIO

@MainActor
struct ArtworkImageView: View {
    let imageURL: String
    var fallbackURL: String = ""
    var maxPixelSize: Int = 512
    @State private var image: CGImage?
    @State private var errorMessage: String?
    @State private var retry = 0

    var body: some View {
        Group {
            if let image {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .accessibilityLabel("Artwork image")
            } else if let errorMessage {
                VStack(spacing: 8) {
                    Image(systemName: "photo.badge.exclamationmark")
                    Text(errorMessage).font(.caption)
                    Button("Retry Image") { retry += 1 }
                }
                .padding()
            } else {
                ProgressView("Loading image")
                    .padding()
            }
        }
        .task(id: "\(imageURL)|\(fallbackURL)|\(retry)") {
            await load()
        }
    }

    @MainActor
    private func load() async {
        image = nil
        errorMessage = nil
        let urls = [imageURL, fallbackURL].compactMap(ArtworkImageCache.imageURL)
        guard !urls.isEmpty else {
            errorMessage = "No image is available for this artwork."
            return
        }
        var lastError: Error = ArtworkImageCache.CacheError.invalidImage
        for url in urls {
            do {
                let data = try await ArtworkImageCache.shared.data(for: url)
                try Task.checkCancellation()
                let size = maxPixelSize
                let thumbnail = try await Task.detached(priority: .userInitiated) {
                    guard let source = CGImageSourceCreateWithData(data as CFData, [
                            kCGImageSourceShouldCache: false
                          ] as CFDictionary),
                          let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                            kCGImageSourceCreateThumbnailFromImageAlways: true,
                            kCGImageSourceCreateThumbnailWithTransform: true,
                            kCGImageSourceThumbnailMaxPixelSize: size,
                            kCGImageSourceShouldCacheImmediately: true
                          ] as CFDictionary) else {
                        throw ArtworkImageCache.CacheError.invalidImage
                    }
                    return image
                }.value
                try Task.checkCancellation()
                image = thumbnail
                return
            } catch {
                if Task.isCancelled { return }
                if error is ArtworkImageCache.CacheError {
                    await ArtworkImageCache.shared.remove(for: url)
                }
                lastError = error
            }
        }
        guard !Task.isCancelled else { return }
        errorMessage = (lastError as? ArtworkImageCache.CacheError)?.localizedDescription
            ?? "Image unavailable. Connect to the internet and retry."
    }
}
