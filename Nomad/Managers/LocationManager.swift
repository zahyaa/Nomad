//
//  LocationManager.swift
//  Nomad
//

import CoreLocation
import SwiftUI

@Observable
@MainActor
final class LocationManager: NSObject {
    var currentLocation: CLLocation?
    var locationName: String = "Unknown location"
    var cityName: String?
    var stateName: String?
    var countryName: String?
    var countryCode: String?
    var authorizationStatus: CLAuthorizationStatus

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    nonisolated(unsafe) private var authTask: Task<Void, Never>?
    nonisolated(unsafe) private var geocodeTask: Task<Void, Never>?

    override init() {
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        // Defer the auth request and any updates until after init returns,
        // so the delegate's `nonisolated` callbacks can't fire before `self`
        // is fully constructed. Also skip the request entirely if the
        // Info.plist key is missing — iOS aborts the process otherwise.
        let hasUsageDescription = Bundle.main.object(
            forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription"
        ) != nil
        authTask = Task { @MainActor [weak self] in
            guard let self, hasUsageDescription else {
                await self?.updateLocationName("Add NSLocationWhenInUseUsageDescription to Info.plist.")
                return
            }
            self.manager.requestWhenInUseAuthorization()
            if self.authorizationStatus == .authorizedWhenInUse || self.authorizationStatus == .authorizedAlways {
                self.manager.startUpdatingLocation()
            }
        }
    }
    
    deinit {
        authTask?.cancel()
        geocodeTask?.cancel()
    }
    
    private func updateLocationName(_ name: String) {
        locationName = name
    }

    func requestUpdate() {
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        } else {
            manager.requestWhenInUseAuthorization()
        }
    }

    private func reverseGeocode(_ location: CLLocation) {
        // Cancel any in-flight geocode request
        geocodeTask?.cancel()
        geocoder.cancelGeocode()
        
        geocodeTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                guard let place = placemarks.first else { return }
                
                self.cityName = place.locality
                self.stateName = place.administrativeArea
                self.countryName = place.country
                self.countryCode = place.isoCountryCode

                let parts = [place.locality, place.country].compactMap { $0 }
                if !parts.isEmpty {
                    self.locationName = parts.joined(separator: ", ")
                } else if let name = place.name {
                    self.locationName = name
                }
            } catch {
                // Geocode failed, keep existing location name
            }
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.startUpdatingLocation()
            } else if status == .denied || status == .restricted {
                self.locationName = "Unknown location"
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = latest
            self.reverseGeocode(latest)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didFailWithError error: Error) {
        Task { @MainActor in
            if self.currentLocation == nil {
                self.locationName = "Unknown location"
            }
        }
    }
}
