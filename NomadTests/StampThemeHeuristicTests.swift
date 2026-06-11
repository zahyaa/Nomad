//
//  StampThemeHeuristicTests.swift
//  NomadTests
//

import Testing
import CoreLocation
@testable import Nomad

struct StampThemeHeuristicTests {

    @Test func defaultsToCityWhenCoordinateIsNil() {
        let theme = StampThemeHeuristic.theme(for: nil)
        #expect(theme == StampTheme.city.rawValue)
    }

    @Test func defaultsToCityForArbitraryCoordinate() {
        let coord = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let theme = StampThemeHeuristic.theme(for: coord)
        #expect(theme == StampTheme.city.rawValue)
    }

    @Test func stampThemeEnumIsExhaustive() {
        let all = StampTheme.allCases.map(\.rawValue).sorted()
        #expect(all == ["city", "coast", "countryside", "mountain"])
    }
}
