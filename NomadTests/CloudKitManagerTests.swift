//
//  CloudKitManagerTests.swift
//  NomadTests
//

import Testing
import Foundation
@testable import Nomad

@MainActor
struct CloudKitManagerTests {

    private func reset() {
        UserDefaults.standard.removeObject(forKey: "nomad.currentUsername")
        // Force-enable so tests start from a known state.
        CloudKitManager.shared.enable()
    }

    @Test func disableForTestingMakesIsEnabledFalse() {
        reset()
        #expect(CloudKitManager.shared.isEnabled == true)
        CloudKitManager.shared.disableForTesting()
        #expect(CloudKitManager.shared.isEnabled == false)
        CloudKitManager.shared.enable()
        #expect(CloudKitManager.shared.isEnabled == true)
    }

    @Test func currentUsernameRoundTrip() {
        reset()
        #expect(CloudKitManager.shared.currentUsername() == nil)
        CloudKitManager.shared.setCurrentUsername("alice")
        #expect(CloudKitManager.shared.currentUsername() == "alice")
        UserDefaults.standard.removeObject(forKey: "nomad.currentUsername")
    }

    // When disabled, queries return empty results without touching CloudKit.

    @Test func findUserReturnsNilWhenDisabled() async throws {
        reset()
        CloudKitManager.shared.disableForTesting()
        let result = try await CloudKitManager.shared.findUser(username: "anyone")
        #expect(result == nil)
    }

    @Test func searchUsersReturnsEmptyWhenDisabled() async throws {
        reset()
        CloudKitManager.shared.disableForTesting()
        let result = try await CloudKitManager.shared.searchUsers(prefix: "a")
        #expect(result.isEmpty)
    }

    @Test func searchUsersReturnsEmptyForEmptyPrefix() async throws {
        reset()
        CloudKitManager.shared.disableForTesting()
        let result = try await CloudKitManager.shared.searchUsers(prefix: "")
        #expect(result.isEmpty)
    }

    @Test func isUsernameAvailableReturnsTrueWhenDisabled() async throws {
        reset()
        CloudKitManager.shared.disableForTesting()
        let available = try await CloudKitManager.shared.isUsernameAvailable("whatever")
        #expect(available == true)
    }

    @Test func fetchReceivedPostcardsReturnsEmptyWhenDisabled() async throws {
        reset()
        CloudKitManager.shared.disableForTesting()
        let result = try await CloudKitManager.shared.fetchReceivedPostcards()
        #expect(result.isEmpty)
    }

    @Test func sendPostcardSimulatedSuccessInDisabledMode() async throws {
        reset()
        CloudKitManager.shared.disableForTesting()
        CloudKitManager.shared.setCurrentUsername("tester")
        let card = Postcard(
            rawImageData: Data([0xAA]),
            locationName: "Nowhere",
            latitude: 0,
            longitude: 0
        )
        try await CloudKitManager.shared.sendPostcard(card, to: "friend")
        #expect(card.senderUsername == "tester")
    }

    @Test func ensureReceiveSubscriptionIsNoOpWhenDisabled() async {
        reset()
        CloudKitManager.shared.disableForTesting()
        await CloudKitManager.shared.ensureReceiveSubscription()
        // No assertions — purely verifying we don't crash or throw.
    }

    @Test func upsertUserRecordThrowsWhenDisabled() async {
        reset()
        CloudKitManager.shared.disableForTesting()
        await #expect(throws: CloudKitError.self) {
            _ = try await CloudKitManager.shared.upsertUserRecord(
                appleUserID: "id",
                username: "u",
                avatar: nil
            )
        }
    }

    @Test func cloudKitErrorDescriptions() {
        #expect(CloudKitError.recipientNotFound.errorDescription?.isEmpty == false)
        #expect(CloudKitError.noRenderedImage.errorDescription?.isEmpty == false)
        #expect(CloudKitError.notAuthenticated.errorDescription?.isEmpty == false)
        #expect(CloudKitError.cloudKitDisabled.errorDescription?.isEmpty == false)
    }
}
