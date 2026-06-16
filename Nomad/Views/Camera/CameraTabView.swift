//
//  CameraTabView.swift
//  Nomad
//

import SwiftUI
import SwiftData
import UIKit
import CoreLocation
import os

struct CameraTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var location = LocationManager()
    @State private var path = NavigationPath()
    @State private var pendingPostcard: Postcard?

    var body: some View {
        NavigationStack(path: $path) {
            CameraView { image in
                handleCapture(image)
            }
            .navigationDestination(for: PostcardRoute.self) { route in
                PostcardComposerView(postcard: route.postcard)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func handleCapture(_ image: UIImage) {
        let quality = UserSettings.shared.photoQuality
        guard let data = ImageCompressor.compress(image, quality: quality) else { return }
        let coord = location.currentLocation?.coordinate
        let theme = StampThemeHeuristic.theme(for: coord)
        let postcard = Postcard(
            rawImageData: data,
            locationName: location.locationName,
            latitude: coord?.latitude ?? 0,
            longitude: coord?.longitude ?? 0,
            timestamp: .now,
            stampTheme: theme,
            stateName: location.stateName,
            countryName: location.countryName,
            countryCode: location.countryCode
        )
        modelContext.insert(postcard)
        
        // Fetch weather data asynchronously
        if let coordinate = coord, #available(iOS 16.0, *) {
            Task {
                do {
                    let weather = try await WeatherService.fetchWeather(for: coordinate)
                    postcard.weatherCondition = weather.condition
                    postcard.temperature = weather.temperature
                    postcard.weatherIcon = weather.icon
                    try? modelContext.save()
                } catch {
                    // Weather fetch failed, continue without weather data
                    Log.weather.error("Weather fetch failed: \(error.localizedDescription, privacy: .public)")
                }
            }
        }
        
        // Save immediately to ensure persistence before navigation
        do {
            try modelContext.save()
            path.append(PostcardRoute(postcard: postcard))
        } catch {
            Log.storage.error("Failed to save postcard: \(error.localizedDescription, privacy: .public)")
        }
    }
}

struct PostcardRoute: Hashable {
    let postcard: Postcard
    
    static func == (lhs: PostcardRoute, rhs: PostcardRoute) -> Bool {
        lhs.postcard.id == rhs.postcard.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(postcard.id)
    }
}
