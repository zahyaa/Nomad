//
//  PostcardExporter.swift
//  Nomad
//

import SwiftUI
import UIKit
import PDFKit

enum PostcardExporter {
    enum ExportError: LocalizedError {
        case noPostcards
        case renderFailed
        case pdfCreationFailed
        case saveFailed
        
        var errorDescription: String? {
            switch self {
            case .noPostcards:
                return "No postcards to export"
            case .renderFailed:
                return "Failed to render postcard"
            case .pdfCreationFailed:
                return "Failed to create PDF"
            case .saveFailed:
                return "Failed to save file"
            }
        }
    }
    
    /// Export a single postcard as an image
    static func exportImage(_ postcard: Postcard) async throws -> URL {
        guard let image = await PostcardRenderer.renderInBackground(postcard) else {
            throw ExportError.renderFailed
        }
        
        guard let data = image.pngData() else {
            throw ExportError.renderFailed
        }
        
        let filename = "\(postcard.locationName.replacingOccurrences(of: " ", with: "_"))_\(postcard.timestamp.formatted(date: .numeric, time: .omitted)).png"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        try data.write(to: url)
        return url
    }
    
    /// Export multiple postcards as a PDF
    static func exportPDF(postcards: [Postcard], title: String = "My Postcards") async throws -> URL {
        guard !postcards.isEmpty else {
            throw ExportError.noPostcards
        }
        
        let pdfRect = CGRect(x: 0, y: 0, width: 612, height: 792) // Letter size
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(title).pdf")
        
        guard let pdfContext = CGContext(url as CFURL, mediaBox: nil, nil) else {
            throw ExportError.pdfCreationFailed
        }
        
        for postcard in postcards {
            guard let image = await PostcardRenderer.renderInBackground(postcard) else {
                continue
            }
            
            // Start new page
            pdfContext.beginPDFPage(nil)
            
            // Calculate image size to fit in page with margins
            let margin: CGFloat = 50
            let maxWidth = pdfRect.width - (margin * 2)
            let maxHeight = pdfRect.height - (margin * 2)
            
            let imageSize = image.size
            let aspectRatio = imageSize.width / imageSize.height
            var drawSize = CGSize(width: maxWidth, height: maxWidth / aspectRatio)
            
            if drawSize.height > maxHeight {
                drawSize = CGSize(width: maxHeight * aspectRatio, height: maxHeight)
            }
            
            // Center the image
            let x = (pdfRect.width - drawSize.width) / 2
            let y = (pdfRect.height - drawSize.height) / 2
            let drawRect = CGRect(x: x, y: y, width: drawSize.width, height: drawSize.height)
            
            // Draw image
            if let cgImage = image.cgImage {
                pdfContext.draw(cgImage, in: drawRect)
            }
            
            // Add location and date text
            let textY = y + drawSize.height + 20
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraphStyle
            ]
            
            let text = "\(postcard.locationName) • \(postcard.timestamp.formatted(date: .long, time: .omitted))"
            let attributedString = NSAttributedString(string: text, attributes: attributes)
            let textRect = CGRect(x: margin, y: textY, width: pdfRect.width - (margin * 2), height: 30)
            attributedString.draw(in: textRect)
            
            pdfContext.endPDFPage()
        }
        
        pdfContext.closePDF()
        return url
    }
    
    /// Export all postcards as individual images in a zip file
    static func exportZip(postcards: [Postcard]) async throws -> URL {
        // For simplicity, we'll just return a folder URL
        // In a real app, you might want to use a zip library
        guard !postcards.isEmpty else {
            throw ExportError.noPostcards
        }
        
        let exportFolder = FileManager.default.temporaryDirectory
            .appendingPathComponent("Postcards_Export_\(Date().timeIntervalSince1970)")
        
        try FileManager.default.createDirectory(at: exportFolder, withIntermediateDirectories: true)
        
        for (index, postcard) in postcards.enumerated() {
            guard let image = await PostcardRenderer.renderInBackground(postcard) else {
                continue
            }
            
            guard let data = image.pngData() else {
                continue
            }
            
            let filename = String(format: "%03d_%@.png", 
                                index + 1,
                                postcard.locationName.replacingOccurrences(of: " ", with: "_"))
            let fileURL = exportFolder.appendingPathComponent(filename)
            try data.write(to: fileURL)
        }
        
        return exportFolder
    }
}
