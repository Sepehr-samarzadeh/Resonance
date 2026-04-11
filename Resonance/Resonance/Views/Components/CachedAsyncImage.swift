//  CachedAsyncImage.swift
//  Resonance

import SwiftUI
import UIKit

// MARK: - ImageCache

/// In-memory image cache backed by `NSCache` for efficient profile photo loading.
final class ImageCache: Sendable {

    static let shared = ImageCache()

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
    }

    func image(for url: URL) -> Image? {
        guard let cached = cache.object(forKey: url.absoluteString as NSString) else {
            return nil
        }
        return Image(uiImage: cached)
    }

    func store(_ data: Data, for url: URL) {
        guard let uiImage = UIImage(data: data) else { return }
        cache.setObject(uiImage, forKey: url.absoluteString as NSString)
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
