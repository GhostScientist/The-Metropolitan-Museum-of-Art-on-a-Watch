//
//  ImageLoader.swift
//  The Tiny Met
//

import ImageIO
import SwiftUI
import UIKit

/// Downloads, downsamples, and caches remote artwork.
///
/// The Met serves original images of 8 MB and more. Decoding those on a watch
/// stalls the UI and invites a memory kill, so every image is decoded straight
/// to a bitmap no larger than `maxPixelSize` on its long edge via ImageIO,
/// off the main thread, and the result is kept in a small memory cache.
/// URLSession's disk cache holds the encoded bytes across launches.
actor ImageLoader {
    static let shared = ImageLoader()

    private let session: URLSession
    private let memoryCache = NSCache<NSString, UIImage>()
    private var inFlight: [NSString: Task<UIImage?, Never>] = [:]

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(
            memoryCapacity: 4 * 1024 * 1024,
            diskCapacity: 64 * 1024 * 1024
        )
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        session = URLSession(configuration: configuration)
        memoryCache.countLimit = 80
    }

    func image(for urlString: String, maxPixelSize: CGFloat) async -> UIImage? {
        guard !urlString.isEmpty, let url = URL(string: urlString) else { return nil }
        let key = "\(urlString)#\(Int(maxPixelSize))" as NSString

        if let cached = memoryCache.object(forKey: key) {
            return cached
        }
        if let existing = inFlight[key] {
            return await existing.value
        }

        let task = Task<UIImage?, Never> { [session] in
            guard let (data, _) = try? await session.data(from: url) else { return nil }
            return ImageLoader.downsample(data, maxPixelSize: maxPixelSize)
        }
        inFlight[key] = task
        let image = await task.value
        inFlight[key] = nil

        if let image {
            memoryCache.setObject(image, forKey: key)
        }
        return image
    }

    /// A small bitmap of a bundled asset, for use as a blurred backdrop.
    func thumbnail(named assetName: String, maxPixelSize: CGFloat) -> UIImage? {
        let key = "asset:\(assetName)#\(Int(maxPixelSize))" as NSString
        if let cached = memoryCache.object(forKey: key) {
            return cached
        }
        guard let data = UIImage(named: assetName)?.jpegData(compressionQuality: 0.8),
              let image = ImageLoader.downsample(data, maxPixelSize: maxPixelSize)
        else { return nil }
        memoryCache.setObject(image, forKey: key)
        return image
    }

    nonisolated static func downsample(_ data: Data, maxPixelSize: CGFloat) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else {
            return nil
        }
        let thumbnailOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ] as CFDictionary
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}

enum RemoteImagePhase: Equatable {
    case loading
    case failure
}

/// A remote image that is fetched through `ImageLoader`, so it is always
/// downsampled to a sensible size before it reaches SwiftUI.
struct RemoteImage<Content: View, Placeholder: View>: View {
    private let url: String
    private let maxPixelSize: CGFloat
    private let content: (Image) -> Content
    private let placeholder: (RemoteImagePhase) -> Placeholder

    @State private var image: UIImage?
    @State private var loadedURL: String?
    @State private var didFail = false

    init(
        url: String,
        maxPixelSize: CGFloat,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping (RemoteImagePhase) -> Placeholder
    ) {
        self.url = url
        self.maxPixelSize = maxPixelSize
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        ZStack {
            if let image, loadedURL == url {
                content(Image(uiImage: image))
                    .transition(.opacity)
            } else {
                placeholder(didFail ? .failure : .loading)
            }
        }
        .animation(.easeOut(duration: 0.25), value: loadedURL)
        .task(id: url) {
            guard loadedURL != url else { return }
            didFail = false
            let loaded = await ImageLoader.shared.image(for: url, maxPixelSize: maxPixelSize)
            guard !Task.isCancelled else { return }
            image = loaded
            loadedURL = loaded == nil ? nil : url
            didFail = loaded == nil
        }
    }
}
