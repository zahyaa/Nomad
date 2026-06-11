//
//  ModelsTests.swift
//  NomadTests
//

import Testing
import Foundation
import SwiftData
@testable import Nomad

@MainActor
struct ModelsTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Postcard.self, User.self, configurations: config)
    }

    // MARK: - PostcardStatus / PostcardFontStyle enums

    @Test func postcardStatusRawValues() {
        #expect(PostcardStatus.draft.rawValue == "draft")
        #expect(PostcardStatus.sent.rawValue == "sent")
        #expect(PostcardStatus.received.rawValue == "received")
    }

    @Test func postcardStatusFromRawValue() {
        #expect(PostcardStatus(rawValue: "draft") == .draft)
        #expect(PostcardStatus(rawValue: "sent") == .sent)
        #expect(PostcardStatus(rawValue: "received") == .received)
        #expect(PostcardStatus(rawValue: "unknown") == nil)
    }

    @Test func fontStyleAllCases() {
        #expect(PostcardFontStyle.allCases == [.casual, .classic])
    }

    @Test func fontStyleLabels() {
        #expect(PostcardFontStyle.casual.label == "Casual")
        #expect(PostcardFontStyle.classic.label == "Classic")
    }

    @Test func fontStyleIdentifiable() {
        #expect(PostcardFontStyle.casual.id == "casual")
        #expect(PostcardFontStyle.classic.id == "classic")
    }

    // MARK: - User

    @Test func userInitDefaultsCreatedAtToNow() {
        let before = Date()
        let user = User(id: "abc", username: "tester")
        let after = Date()
        #expect(user.id == "abc")
        #expect(user.username == "tester")
        #expect(user.avatarData == nil)
        #expect(user.createdAt >= before && user.createdAt <= after)
    }

    @Test func userInsertRoundTrip() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let user = User(id: "id-1", username: "alice")
        ctx.insert(user)
        try ctx.save()

        let fetched = try ctx.fetch(FetchDescriptor<User>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.username == "alice")
    }

    // MARK: - Postcard

    @Test func postcardInitDefaults() {
        let card = Postcard(
            rawImageData: Data([0x01]),
            locationName: "Austin",
            latitude: 30.27,
            longitude: -97.74
        )
        #expect(card.renderedImageData == nil)
        #expect(card.message == nil)
        #expect(card.stampTheme == "city")
        #expect(card.status == .draft)
        #expect(card.fontStyle == .casual)
        #expect(card.recipientUsername == nil)
        #expect(card.senderUsername == nil)
    }

    @Test func postcardStatusComputedRoundTrip() {
        let card = Postcard(
            rawImageData: Data(),
            locationName: "Tokyo",
            latitude: 35.68,
            longitude: 139.69
        )
        card.status = .sent
        #expect(card.statusRaw == "sent")
        #expect(card.status == .sent)

        card.status = .received
        #expect(card.statusRaw == "received")
        #expect(card.status == .received)
    }

    @Test func postcardStatusFallsBackToDraftForUnknownRaw() {
        let card = Postcard(
            rawImageData: Data(),
            locationName: "X",
            latitude: 0,
            longitude: 0
        )
        card.statusRaw = "garbage"
        #expect(card.status == .draft)
    }

    @Test func postcardFontStyleComputedRoundTrip() {
        let card = Postcard(
            rawImageData: Data(),
            locationName: "X",
            latitude: 0,
            longitude: 0
        )
        card.fontStyle = .classic
        #expect(card.fontStyleRaw == "classic")
        #expect(card.fontStyle == .classic)
    }

    @Test func postcardInsertRoundTrip() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let card = Postcard(
            rawImageData: Data([0xFF, 0x00]),
            locationName: "Paris, France",
            latitude: 48.85,
            longitude: 2.35,
            message: "Bonjour",
            stampTheme: "city",
            status: .sent,
            recipientUsername: "bob"
        )
        ctx.insert(card)
        try ctx.save()

        let fetched = try ctx.fetch(FetchDescriptor<Postcard>())
        #expect(fetched.count == 1)
        let stored = fetched[0]
        #expect(stored.locationName == "Paris, France")
        #expect(stored.message == "Bonjour")
        #expect(stored.recipientUsername == "bob")
        #expect(stored.status == .sent)
    }

    @Test func postcardPredicateFiltersByStatus() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let draft = Postcard(rawImageData: Data(), locationName: "A", latitude: 0, longitude: 0)
        let sent = Postcard(rawImageData: Data(), locationName: "B", latitude: 0, longitude: 0, status: .sent)
        let received = Postcard(rawImageData: Data(), locationName: "C", latitude: 0, longitude: 0, status: .received)
        ctx.insert(draft); ctx.insert(sent); ctx.insert(received)
        try ctx.save()

        let receivedOnly = try ctx.fetch(
            FetchDescriptor<Postcard>(predicate: #Predicate { $0.statusRaw == "received" })
        )
        #expect(receivedOnly.count == 1)
        #expect(receivedOnly.first?.locationName == "C")

        let nonReceived = try ctx.fetch(
            FetchDescriptor<Postcard>(predicate: #Predicate { $0.statusRaw != "received" })
        )
        #expect(nonReceived.count == 2)
    }
}
