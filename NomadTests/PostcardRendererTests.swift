//
//  PostcardRendererTests.swift
//  NomadTests
//

import Testing
import Foundation
import SwiftData
import UIKit
@testable import Nomad

@MainActor
struct PostcardRendererTests {

    private func makeCard() -> Postcard {
        // Tiny 1x1 PNG so the renderer has something to work with.
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
        let png = renderer.pngData { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        return Postcard(
            rawImageData: png,
            locationName: "Test City",
            latitude: 1,
            longitude: 2,
            message: "hi",
            stampTheme: "city"
        )
    }

    @Test func renderPostcardProducesNonNilImage() {
        let card = makeCard()
        let image = PostcardRenderer.renderPostcard(card)
        #expect(image != nil)
        if let image {
            #expect(image.size.width > 0)
            #expect(image.size.height > 0)
        }
    }

    @Test func renderAndStoreWritesRenderedData() {
        let card = makeCard()
        #expect(card.renderedImageData == nil)
        let image = PostcardRenderer.renderAndStore(card)
        #expect(image != nil)
        #expect(card.renderedImageData != nil)
        #expect((card.renderedImageData?.count ?? 0) > 0)
    }
}
