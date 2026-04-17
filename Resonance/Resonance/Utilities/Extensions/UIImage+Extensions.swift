//  UIImage+Extensions.swift
//  Resonance

#if canImport(UIKit)
import UIKit

extension UIImage {

    /// Returns a copy of the image with normalized orientation (`.up`).
    ///
    /// Photos taken on iOS often carry EXIF orientation metadata rather than
    /// physically rotated pixels. When the image is re-encoded to JPEG the
    /// metadata can be lost, causing the image to appear rotated. This method
    /// re-draws the image so the pixels match `.up` orientation.
    func normalizedOrientation() -> UIImage? {
        guard imageOrientation != .up else { return self }

        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalized
    }

    /// Extracts the dominant color from the image by downscaling to a small
    /// size and averaging the pixel colors.
    ///
    /// Runs entirely on the CPU using Core Graphics — no Metal or CIFilter
    /// dependency. The image is scaled to 40x40 to keep the work minimal.
    /// - Returns: A `UIColor` representing the dominant tone, or `nil` on failure.
    func dominantColor() -> UIColor? {
        let targetSize = CGSize(width: 40, height: 40)
        guard let cgImage = cgImage else { return nil }

        let width = Int(targetSize.width)
        let height = Int(targetSize.height)
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.draw(cgImage, in: CGRect(origin: .zero, size: targetSize))

        var totalR: Double = 0
        var totalG: Double = 0
        var totalB: Double = 0
        let pixelCount = width * height

        for i in 0..<pixelCount {
            let offset = i * bytesPerPixel
            totalR += Double(pixelData[offset])
            totalG += Double(pixelData[offset + 1])
            totalB += Double(pixelData[offset + 2])
        }

        let count = Double(pixelCount)
        return UIColor(
            red: totalR / (count * 255),
            green: totalG / (count * 255),
            blue: totalB / (count * 255),
            alpha: 1
        )
    }
}
#endif
