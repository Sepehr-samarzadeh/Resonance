//  CachedAsyncImage.swift
//  Resonance

import SwiftUI
import CoreGraphics
import ImageIO

// MARK: - CachedImageData

/// Wrapper to hold image `Data` in `NSCache` (which requires reference types).
private final class CachedImageData: @unchecked Sendable {
    let data: Data
    init(_ data: Data) { self.data = data }
}

// MARK: - ImageCache

/// In-memory image cache backed by `NSCache` for efficient profile photo loading.
/// Uses `CoreGraphics` instead of UIKit to stay SwiftUI-only.
final class ImageCache: Sendable {

    static let shared = ImageCache()

    private let cache = NSCache<NSString, CachedImageData>()

    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
    }

    func image(for url: URL) -> Image? {
        guard let cached = cache.object(forKey: url.absoluteString as NSString) else {
            return nil
        }
        guard let source = CGImageSourceCreateWithData(cached.data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }
        return Image(decorative: cgImage, scale: 1.0)
    }

    func store(_ data: Data, for url: URL) {
        // Validate that the data is a valid image before caching
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceGetCount(source) > 0 else { return }
        cache.setObject(CachedImageData(data), forKey: url.absoluteString as NSString, cost: data.count)
    }
}

// MARK: - CachedAsyncImage

/// A drop-in replacement for `AsyncImage` with in-memory caching.
/// Avoids re-downloading images on every re-render.
struct CachedAsyncImage<Content: View, Placeholder: View>: View {

    // MARK: - Properties

    let url: URL?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var loadedImage: Image?

    // MARK: - Body

    var body: some View {
        Group {
            if let loadedImage {
                content(loadedImage)
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            await loadImage()
        }
    }

    // MARK: - Loading

    private func loadImage() async {
        guard let url else {
            loadedImage = nil
            return
        }

        // Check cache first
        if let cached = ImageCache.shared.image(for: url) {
            loadedImage = cached
            return
        }

        // Download
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            ImageCache.shared.store(data, for: url)
            loadedImage = ImageCache.shared.image(for: url)
        } catch {
            loadedImage = nil
        }
    }
}
