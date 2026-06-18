//
//  CloudKitManager.swift
//  Nomad
//

import CloudKit
import Foundation
import os
import SwiftData
import UIKit

enum CloudKitError: LocalizedError {
    case recipientNotFound
    case noRenderedImage
    case notAuthenticated
    case cloudKitDisabled
    case networkUnavailable
    case quotaExceeded
    case permissionDenied
    case serverRejected
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .recipientNotFound: 
            return "We couldn't find that Nomad."
        case .noRenderedImage: 
            return "Render the postcard before sending."
        case .notAuthenticated: 
            return "Sign in with Apple to send postcards."
        case .cloudKitDisabled: 
            return "CloudKit isn't configured — you're in test mode."
        case .networkUnavailable:
            return "No internet connection. Try again when you're online."
        case .quotaExceeded:
            return "You've reached your CloudKit storage limit."
        case .permissionDenied:
            return "iCloud access denied. Enable it in Settings."
        case .serverRejected:
            return "The server rejected your request. Try again later."
        case .underlying(let error): 
            return error.localizedDescription
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .recipientNotFound:
            return "Check the username and try again."
        case .noRenderedImage:
            return "Tap 'Prepare to Share' first."
        case .notAuthenticated:
            return "Complete the onboarding to set up your account."
        case .cloudKitDisabled:
            return "This is normal during development."
        case .networkUnavailable:
            return "Check your internet connection and try again."
        case .quotaExceeded:
            return "Delete some old data or upgrade your iCloud storage."
        case .permissionDenied:
            return "Open Settings > [Your Name] > iCloud and enable this app."
        case .serverRejected:
            return "Wait a few minutes and try again."
        case .underlying:
            return "If this persists, contact support."
        }
    }
    
    /// Maps a CKError to a more user-friendly CloudKitError
    static func from(_ error: Error) -> CloudKitError {
        guard let ckError = error as? CKError else {
            return .underlying(error)
        }
        
        switch ckError.code {
        case .networkUnavailable, .networkFailure:
            return .networkUnavailable
        case .quotaExceeded:
            return .quotaExceeded
        case .notAuthenticated:
            return .notAuthenticated
        case .permissionFailure:
            return .permissionDenied
        case .serverRejectedRequest, .serverResponseLost:
            return .serverRejected
        default:
            return .underlying(error)
        }
    }
}

enum CKRecordType {
    static let user = "UserRecord"
    static let postcard = "PostcardRecord"
}

@MainActor
final class CloudKitManager {
    static let shared = CloudKitManager()

    private static let enabledKey = "nomad.cloudKitEnabled"

    /// CloudKit is opt-in: until the iCloud entitlement is configured,
    /// `CKContainer.default()` will trap. We default to disabled and let
    /// callers explicitly turn it on after wiring up the entitlement.
    var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: Self.enabledKey)
    }

    func disableForTesting() {
        UserDefaults.standard.set(false, forKey: Self.enabledKey)
    }

    func enable() {
        UserDefaults.standard.set(true, forKey: Self.enabledKey)
    }

    private lazy var container: CKContainer = CKContainer.default()
    private lazy var database: CKDatabase = container.publicCloudDatabase

    private init() {
        // Default Sync to ON for fresh installs. Once the user explicitly
        // toggles it in Settings, the stored value sticks and overrides
        // this default. `register` only applies when no value has been
        // set yet, so existing installs keep their last choice.
        UserDefaults.standard.register(defaults: [Self.enabledKey: true])
    }

    // MARK: - Account / Identity

    func currentUsername() -> String? {
        UserDefaults.standard.string(forKey: "nomad.currentUsername")
    }

    func setCurrentUsername(_ username: String) {
        UserDefaults.standard.set(username, forKey: "nomad.currentUsername")
    }

    /// Cached during sign-in so we can backfill the UserRecord later if
    /// the user enables Sync after onboarding finishes.
    func setPendingAppleUserID(_ appleUserID: String) {
        UserDefaults.standard.set(appleUserID, forKey: "nomad.pendingAppleUserID")
    }

    func pendingAppleUserID() -> String? {
        UserDefaults.standard.string(forKey: "nomad.pendingAppleUserID")
    }

    /// Idempotent. Upserts the UserRecord using the cached Apple ID +
    /// current username. Safe to call from the Sync toggle setter or
    /// any first-CloudKit-action site. No-op when Sync is off.
    func upsertCurrentUserIfNeeded() async {
        guard isEnabled,
              let appleUserID = pendingAppleUserID(),
              let username = currentUsername(),
              !username.isEmpty else { return }
        do {
            _ = try await upsertUserRecord(
                appleUserID: appleUserID,
                username: username,
                avatar: nil
            )
        } catch {
            Log.cloudKit.error("Backfill upsertUserRecord failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - User Records

    func findUser(username: String) async throws -> CKRecord? {
        guard isEnabled else { return nil }
        let predicate = NSPredicate(format: "username == %@", username)
        let query = CKQuery(recordType: CKRecordType.user, predicate: predicate)
        do {
            let result = try await database.records(matching: query, resultsLimit: 1)
            return try result.matchResults.first?.1.get()
        } catch {
            throw CloudKitError.from(error)
        }
    }

    func searchUsers(prefix: String) async throws -> [CKRecord] {
        guard isEnabled else { return [] }
        guard !prefix.isEmpty else { return [] }
        let predicate = NSPredicate(format: "username BEGINSWITH %@", prefix)
        let query = CKQuery(recordType: CKRecordType.user, predicate: predicate)
        do {
            let result = try await database.records(matching: query, resultsLimit: 20)
            return result.matchResults.compactMap { try? $0.1.get() }
        } catch {
            throw CloudKitError.from(error)
        }
    }

    @discardableResult
    func upsertUserRecord(appleUserID: String, username: String, avatar: Data?) async throws -> CKRecord {
        guard isEnabled else { throw CloudKitError.cloudKitDisabled }
        let recordID = CKRecord.ID(recordName: appleUserID)
        let record: CKRecord
        do {
            record = try await database.record(for: recordID)
        } catch {
            record = CKRecord(recordType: CKRecordType.user, recordID: recordID)
        }
        record["appleUserID"] = appleUserID as CKRecordValue
        record["username"] = username as CKRecordValue
        if let avatar, let url = Self.writeTempFile(data: avatar, ext: "png") {
            record["avatarAsset"] = CKAsset(fileURL: url)
        }
        do {
            return try await database.save(record)
        } catch {
            throw CloudKitError.from(error)
        }
    }

    func isUsernameAvailable(_ username: String) async throws -> Bool {
        guard isEnabled else { return true }
        let existing = try await findUser(username: username)
        return existing == nil
    }

    // MARK: - Sending Postcards

    func sendPostcard(_ postcard: Postcard, to recipient: String) async throws {
        guard isEnabled else {
            // Simulate a successful send for local testing.
            postcard.senderUsername = currentUsername() ?? "test"
            try? await Task.sleep(nanoseconds: 600_000_000)
            return
        }
        guard let imageData = postcard.renderedImageData ?? postcard.rawImageData as Data?,
              let imageURL = Self.writeTempFile(data: imageData, ext: "png") else {
            throw CloudKitError.noRenderedImage
        }
        defer { try? FileManager.default.removeItem(at: imageURL) }

        guard let sender = currentUsername() else {
            throw CloudKitError.notAuthenticated
        }

        let record = CKRecord(recordType: CKRecordType.postcard)
        record["postcardImage"] = CKAsset(fileURL: imageURL)
        record["locationName"] = postcard.locationName as CKRecordValue
        record["latitude"] = postcard.latitude as CKRecordValue
        record["longitude"] = postcard.longitude as CKRecordValue
        if let message = postcard.message {
            record["message"] = message as CKRecordValue
        }
        record["stampTheme"] = postcard.stampTheme as CKRecordValue
        record["senderUsername"] = sender as CKRecordValue
        record["recipientUsername"] = recipient as CKRecordValue
        record["sentAt"] = postcard.timestamp as CKRecordValue

        do {
            _ = try await Self.withRetry { try await self.database.save(record) }
            postcard.senderUsername = sender
        } catch {
            throw CloudKitError.from(error)
        }
    }

    // MARK: - Receiving Postcards

    func fetchReceivedPostcards() async throws -> [CKRecord] {
        guard isEnabled else { return [] }
        guard let username = currentUsername() else { return [] }
        let predicate = NSPredicate(format: "recipientUsername == %@", username)
        let query = CKQuery(recordType: CKRecordType.postcard, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "sentAt", ascending: false)]
        do {
            let result = try await Self.withRetry {
                try await self.database.records(matching: query, resultsLimit: 50)
            }
            return result.matchResults.compactMap { try? $0.1.get() }
        } catch {
            throw CloudKitError.from(error)
        }
    }

    // MARK: - Subscriptions

    func ensureReceiveSubscription() async {
        guard isEnabled else { return }
        guard let username = currentUsername() else { return }
        let subscriptionID = "nomad.receive.\(username)"

        // Check if subscription already exists
        do {
            let existing = try await database.subscription(for: subscriptionID)
            if existing.subscriptionID == subscriptionID {
                return  // Already exists
            }
        } catch let error as CKError {
            // Only treat .unknownItem as "not found"; other errors should be logged
            if error.code != .unknownItem {
                Log.cloudKit.error("Error checking subscription: \(error.localizedDescription, privacy: .public)")
                // Still try to create it below
            }
        } catch {
            Log.cloudKit.error("Unexpected error checking subscription: \(String(describing: error), privacy: .public)")
        }

        // Create the subscription
        let predicate = NSPredicate(format: "recipientUsername == %@", username)
        let subscription = CKQuerySubscription(
            recordType: CKRecordType.postcard,
            predicate: predicate,
            subscriptionID: subscriptionID,
            options: .firesOnRecordCreation
        )
        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true
        info.alertBody = "You received a new postcard."
        info.soundName = "default"
        subscription.notificationInfo = info

        do {
            _ = try await database.save(subscription)
        } catch let error as CKError {
            // If serverRecordChanged, subscription already exists (race condition)
            if error.code == .serverRecordChanged {
                return  // Idempotent: someone else created it
            }
            Log.cloudKit.error("Error creating subscription: \(error.localizedDescription, privacy: .public)")
        } catch {
            Log.cloudKit.error("Unexpected error creating subscription: \(String(describing: error), privacy: .public)")
        }
    }

    // MARK: - Retry

    /// Runs `operation` and retries on transient CloudKit errors with
    /// exponential backoff. Caps at 3 attempts. Honors `retryAfterSeconds`
    /// in the CKError userInfo if the server suggests one.
    static func withRetry<T>(
        maxAttempts: Int = 3,
        baseDelay: TimeInterval = 1.0,
        operation: () async throws -> T
    ) async throws -> T {
        var attempt = 0
        while true {
            attempt += 1
            do {
                return try await operation()
            } catch {
                guard attempt < maxAttempts, Self.isTransient(error) else {
                    throw error
                }
                let suggested = (error as? CKError)?.retryAfterSeconds
                let delay = suggested ?? baseDelay * pow(2, Double(attempt - 1))
                Log.cloudKit.info("Retrying CloudKit op after \(delay, privacy: .public)s (attempt \(attempt, privacy: .public)/\(maxAttempts, privacy: .public))")
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }

    private static func isTransient(_ error: Error) -> Bool {
        guard let ck = error as? CKError else { return false }
        switch ck.code {
        case .networkUnavailable, .networkFailure,
             .serviceUnavailable, .requestRateLimited,
             .zoneBusy, .serverResponseLost:
            return true
        default:
            return false
        }
    }

    // MARK: - Helpers

    static func writeTempFile(data: Data, ext: String) -> URL? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(ext)
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }
}
