//
//  ManagersInitTests.swift
//  NomadTests
//

import Testing
import Foundation
@testable import Nomad

/// Camera and Location managers can't be fully exercised without hardware,
/// but we can confirm their initial state and that they don't crash on init.
@MainActor
struct ManagersInitTests {

    @Test func cameraManagerInitialState() {
        let manager = CameraManager()
        // Status starts unknown and resolves asynchronously.
        #expect(manager.status == .unknown)
        #expect(manager.isUsingFrontCamera == false)
        #expect(manager.lastError == nil)
    }

    @Test func locationManagerInitialState() {
        let manager = LocationManager()
        #expect(manager.currentLocation == nil)
        #expect(manager.locationName == "Unknown location")
    }

    @Test func postcardMessageGeneratorStatusIsObservable() {
        // The status is whatever the device reports — we just verify the call
        // doesn't crash and returns one of the two cases.
        switch PostcardMessageGenerator.status() {
        case .ready:
            #expect(true)
        case .unavailable(let reason):
            #expect(reason.isEmpty == false)
        }
    }
}
