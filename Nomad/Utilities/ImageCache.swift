//
//  ImageCache.swift
//  Nomad
//

import UIKit

/// In-memory cache for frequently accessed images to reduce Data->UIImage conversions
class ImageCache {
    static let shared = ImageCache()
    
    private let cache = NSCache<NSString, UIImage>()
    private let thumbnailCache = NSCache<NSString, UIImage>()
    
    private init() {
        // Configure cache limits
        cache.countLimit = 50  // Max 50 full-size images
        cache.totalCostLimit = 100 * 1024 * 1024  // 100 MB
        
        thumbnailCache.countLimit = 200  // Max 200 thumbnails
        thumbnailCache.totalCostLimit = 20 * 1024 * 1024  // 20 MB
        
        // Clear cache on memory warning
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    /// Get cached image for a postcard ID
    func getImage(for id: String) -> UIImage? {
        return cache.object(forKey: id as NSString)
    }
    
    /// Cache an image for a postcard ID
    func setImage(_ image: UIImage, for id: String) {
        let cost = image.jpegData(compressionQuality: 1.0)?.count ?? 0
        cache.setObject(image, forKey: id as NSString, cost: cost)
    }
    
    /// Get cached thumbnail for a postcard ID
    func getThumbnail(for id: String) -> UIImage? {
        return thumbnailCache.object(forKey: id as NSString)
    }
    
    /// Cache a thumbnail for a postcard ID
    func setThumbnail(_ image: UIImage, for id: String) {
        let cost = image.jpegData(compressionQuality: 0.7)?.count ?? 0
        thumbnailCache.setObject(image, forKey: id as NSString, cost: cost)
    }
    
    /// Clear all cached images
    @objc func clearCache() {
        cache.removeAllObjects()
        thumbnailCache.removeAllObjects()
    }
    
    /// Remove specific image from cache
    func removeImage(for id: String) {
        cache.removeObject(forKey: id as NSString)
        thumbnailCache.removeObject(forKey: id as NSString)
    }
}

/// Convenience extension for Postcard to use ImageCache
extension Postcard {
    /// Get the full-size image, using cache if available
    var cachedImage: UIImage? {
        let cacheKey = id.uuidString
        
        if let cached = ImageCache.shared.getImage(for: cacheKey) {
            return cached
        }
        
        guard let image = UIImage(data: rawImageData) else {
            return nil
        }
        
        ImageCache.shared.setImage(image, for: cacheKey)
        return image
    }
    
    /// Get the thumbnail image, using cache if available
    var cachedThumbnail: UIImage? {
        let cacheKey = "\(id.uuidString)_thumb"
        
        if let cached = ImageCache.shared.getThumbnail(for: cacheKey) {
            return cached
        }
        
        // Try thumbnailData first
        if let thumbnailData = thumbnailData,
           let image = UIImage(data: thumbnailData) {
            ImageCache.shared.setThumbnail(image, for: cacheKey)
            return image
        }
        
        // Fallback to rawImageData
        if let image = UIImage(data: rawImageData) {
            ImageCache.shared.setThumbnail(image, for: cacheKey)
            return image
        }
        
        return nil
    }
}
