//
//  StampThemeHeuristic.swift
//  Nomad
//

import CoreLocation
import MapKit

enum StampTheme: String, CaseIterable {
    case city, coast, mountain, countryside, forest, desert, urban, lake
}

enum StampThemeHeuristic {
    /// Synchronous default used at capture time. Falls back to `.city` when no coordinate is known.
    /// A richer async classification can be done later via `classify(_:)`.
    static func theme(for coordinate: CLLocationCoordinate2D?) -> String {
        guard coordinate != nil else { return StampTheme.city.rawValue }
        return StampTheme.city.rawValue
    }

    /// Best-effort asynchronous classification using MKLocalSearch.
    /// Heuristic: Searches for various POI types to determine the most appropriate stamp theme.
    /// Runs searches on background queue to avoid blocking main actor.
    nonisolated static func classify(_ coordinate: CLLocationCoordinate2D) async -> StampTheme {
        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 5000,
            longitudinalMeters: 5000
        )

        // Check for coastal areas
        let beachRequest = MKLocalSearch.Request()
        beachRequest.naturalLanguageQuery = "ocean beach coast"
        beachRequest.region = region
        if let beach = try? await MKLocalSearch(request: beachRequest).start(),
           !beach.mapItems.isEmpty,
           let firstCoord = beach.mapItems.first?.placemark.location?.coordinate {
            let here = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let there = CLLocation(latitude: firstCoord.latitude, longitude: firstCoord.longitude)
            if here.distance(from: there) < 3000 { return .coast }
        }

        // Check for lakes
        let lakeRequest = MKLocalSearch.Request()
        lakeRequest.naturalLanguageQuery = "lake"
        lakeRequest.region = region
        if let lake = try? await MKLocalSearch(request: lakeRequest).start(),
           !lake.mapItems.isEmpty,
           let firstCoord = lake.mapItems.first?.placemark.location?.coordinate {
            let here = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let there = CLLocation(latitude: firstCoord.latitude, longitude: firstCoord.longitude)
            if here.distance(from: there) < 2000 { return .lake }
        }

        // Check for mountains
        let mountainRequest = MKLocalSearch.Request()
        mountainRequest.naturalLanguageQuery = "mountain peak"
        mountainRequest.region = region
        if let mountain = try? await MKLocalSearch(request: mountainRequest).start(),
           !mountain.mapItems.isEmpty {
            return .mountain
        }

        // Check for forests/parks
        let forestRequest = MKLocalSearch.Request()
        forestRequest.naturalLanguageQuery = "forest park nature reserve"
        forestRequest.region = region
        if let forest = try? await MKLocalSearch(request: forestRequest).start(),
           forest.mapItems.count >= 2 {
            return .forest
        }

        // Check for desert areas
        let desertRequest = MKLocalSearch.Request()
        desertRequest.naturalLanguageQuery = "desert"
        desertRequest.region = region
        if let desert = try? await MKLocalSearch(request: desertRequest).start(),
           !desert.mapItems.isEmpty {
            return .desert
        }

        // Check urban density
        let cityRequest = MKLocalSearch.Request()
        cityRequest.naturalLanguageQuery = "restaurant"
        cityRequest.region = region
        if let city = try? await MKLocalSearch(request: cityRequest).start() {
            if city.mapItems.count >= 20 { return .urban }
            if city.mapItems.count >= 10 { return .city }
            if city.mapItems.count <= 3 { return .countryside }
        }
        
        return .city
    }
}
