//
//  PostcardShareItem.swift
//  Nomad
//

import SwiftUI
import LinkPresentation

/// Custom share item that provides rich metadata for sharing postcards
class PostcardShareItem: NSObject, UIActivityItemSource {
    let image: UIImage
    let postcard: Postcard
    
    init(image: UIImage, postcard: Postcard) {
        self.image = image
        self.postcard = postcard
        super.init()
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return image
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, 
                               itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return image
    }
    
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = "Postcard from \(postcard.locationName)"
        
        if let message = postcard.message {
            metadata.originalURL = URL(string: "nomad://postcard/\(postcard.id.uuidString)")
            // Use message as subtitle/caption
            metadata.iconProvider = NSItemProvider(object: image)
        }
        
        metadata.imageProvider = NSItemProvider(object: image)
        
        return metadata
    }
}
