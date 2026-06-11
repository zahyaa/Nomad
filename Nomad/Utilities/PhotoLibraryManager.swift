//
//  PhotoLibraryManager.swift
//  Nomad
//

import UIKit
import Photos

enum PhotoLibraryManager {
    enum SaveError: LocalizedError {
        case permissionDenied
        case saveFailed(Error)
        case noImage
        
        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Photo library access denied. Enable it in Settings to save postcards."
            case .saveFailed(let error):
                return "Failed to save: \(error.localizedDescription)"
            case .noImage:
                return "No image to save."
            }
        }
    }
    
    /// Checks photo library permission status
    static func authorizationStatus() -> PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .addOnly)
    }
    
    /// Request permission to add photos
    static func requestAuthorization() async -> Bool {
        await PHPhotoLibrary.requestAuthorization(for: .addOnly) == .authorized
    }
    
    /// Saves an image to the photo library
    /// - Parameter image: The image to save
    /// - Returns: The asset identifier if successful
    @discardableResult
    static func saveImage(_ image: UIImage) async throws -> String? {
        // Check permission
        let status = authorizationStatus()
        switch status {
        case .notDetermined:
            let granted = await requestAuthorization()
            guard granted else { throw SaveError.permissionDenied }
        case .authorized, .limited:
            break
        case .denied, .restricted:
            throw SaveError.permissionDenied
        @unknown default:
            throw SaveError.permissionDenied
        }
        
        // Save to library
        return try await withCheckedThrowingContinuation { continuation in
            var assetIdentifier: String?
            
            PHPhotoLibrary.shared().performChanges {
                let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
                assetIdentifier = request.placeholderForCreatedAsset?.localIdentifier
            } completionHandler: { success, error in
                if success {
                    continuation.resume(returning: assetIdentifier)
                } else if let error {
                    continuation.resume(throwing: SaveError.saveFailed(error))
                } else {
                    continuation.resume(throwing: SaveError.saveFailed(NSError(domain: "PhotoLibrary", code: -1)))
                }
            }
        }
    }
}
