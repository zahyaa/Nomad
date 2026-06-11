//
//  ImageCompressor.swift
//  Nomad
//

import UIKit
import CoreGraphics

enum PhotoQuality: String, CaseIterable {
    case high = "High Quality"
    case medium = "Medium"
    case low = "Low (Smaller Size)"
    
    var maxDimension: CGFloat {
        switch self {
        case .high: return 2400
        case .medium: return 2000
        case .low: return 1600
        }
    }
    
    var compressionQuality: CGFloat {
        switch self {
        case .high: return 0.90
        case .medium: return 0.85
        case .low: return 0.75
        }
    }
}

enum ImageCompressor {
    /// Maximum dimensions for postcard images (maintains aspect ratio)
    static let maxDimension: CGFloat = 2000
    
    /// Standard compression quality for JPEG encoding
    static let compressionQuality: CGFloat = 0.85
    
    /// Compresses and resizes a UIImage for postcard storage using specified quality.
    /// - Parameters:
    ///   - image: The original image to compress
    ///   - quality: The photo quality setting to use
    /// - Returns: Compressed JPEG data, or nil if compression failed
    static func compress(_ image: UIImage, quality: PhotoQuality = .medium) -> Data? {
        let resized = resize(image, maxDimension: quality.maxDimension)
        return resized.jpegData(compressionQuality: quality.compressionQuality)
    }
    
    /// Compresses raw data by first loading it as UIImage, then re-compressing.
    /// Useful for normalizing images received from CloudKit.
    /// - Parameters:
    ///   - data: Original image data (any format)
    ///   - quality: The photo quality setting to use
    /// - Returns: Compressed JPEG data, or nil if invalid
    static func compress(_ data: Data, quality: PhotoQuality = .medium) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        return compress(image, quality: quality)
    }
    
    /// Resizes an image to fit within max dimensions while maintaining aspect ratio
    private static func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard size.width > maxDimension || size.height > maxDimension else {
            return image  // Already smaller than max
        }
        
        let aspectRatio = size.width / size.height
        let newSize: CGSize
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    /// Generates a small thumbnail suitable for list views
    /// - Parameters:
    ///   - image: The source image
    ///   - size: Target size (default 100x100)
    /// - Returns: Thumbnail image data
    static func generateThumbnail(from image: UIImage, size: CGFloat = 100) -> Data? {
        let thumbnail = resize(image, maxDimension: size)
        return thumbnail.jpegData(compressionQuality: 0.7)
    }
    
    /// Generates a thumbnail from image data
    /// - Parameters:
    ///   - data: Source image data
    ///   - size: Target size (default 100x100)
    /// - Returns: Thumbnail image data
    static func generateThumbnail(from data: Data, size: CGFloat = 100) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        return generateThumbnail(from: image, size: size)
    }
}
