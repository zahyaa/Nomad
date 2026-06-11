//
//  PostcardRenderer.swift
//  Nomad
//

import SwiftUI
import UIKit

enum PostcardRenderer {
    @MainActor
    static func renderPostcard(_ postcard: Postcard) -> UIImage? {
        let view = PostcardView(postcard: postcard)
            .frame(width: 1200, height: 900)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0
        renderer.proposedSize = .init(width: 1200, height: 900)
        return renderer.uiImage
    }

    /// Renders and persists `renderedImageData` onto the postcard. Returns the
    /// rendered image so the caller can share it immediately.
    @MainActor
    @discardableResult
    static func renderAndStore(_ postcard: Postcard) -> UIImage? {
        guard let image = renderPostcard(postcard) else { return nil }
        if let data = image.pngData() {
            postcard.renderedImageData = data
        }
        return image
    }
    
    /// Renders the postcard on a background task to avoid blocking the main thread.
    /// Returns the rendered image, which the caller can then store in the postcard.
    @MainActor
    static func renderInBackground(_ postcard: Postcard) async -> UIImage? {
        return await Task.detached(priority: .userInitiated) {
            await renderPostcard(postcard)
        }.value
    }
}
