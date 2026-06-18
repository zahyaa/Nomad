//
//  NomadApp.swift
//  Nomad
//

import SwiftUI
import SwiftData
import os

@main
struct NomadApp: App {
    @UIApplicationDelegateAdaptor(NomadAppDelegate.self) var appDelegate

    private let sharedModelContainer: ModelContainer? = Self.makeSharedModelContainer()

    private static let fullSchemaModels: [any PersistentModel.Type] = [
        Postcard.self,
        User.self,
        PostcardCollection.self,
        CustomStamp.self
    ]

    private static let coreSchemaModels: [any PersistentModel.Type] = [
        Postcard.self,
        User.self,
        PostcardCollection.self
    ]

    private static func makeSharedModelContainer() -> ModelContainer? {
        do {
            return try buildContainer(models: fullSchemaModels, inMemory: false)
        } catch {
            Log.storage.error("SwiftData disk container failed for full schema: \(String(describing: error), privacy: .public)")
        }

        do {
            return try buildContainer(models: fullSchemaModels, inMemory: true)
        } catch {
            Log.storage.error("SwiftData in-memory container failed for full schema: \(String(describing: error), privacy: .public)")
        }

        do {
            Log.storage.error("Retrying SwiftData with core schema only")
            return try buildContainer(models: coreSchemaModels, inMemory: true)
        } catch {
            Log.storage.error("SwiftData in-memory container failed for core schema: \(String(describing: error), privacy: .public)")
        }

        return nil
    }

    private static func buildContainer(
        models: [any PersistentModel.Type],
        inMemory: Bool
    ) throws -> ModelContainer {
        let schema = Schema(models)
        // `cloudKitDatabase: .none` keeps SwiftData purely local. Without
        // this, adding the iCloud capability flips SwiftData into
        // auto-sync mode and the container init fails because our models
        // have non-optional properties (CloudKit sync requires every
        // attribute to be optional or have a default). User-to-user
        // delivery still happens via `CloudKitManager` → public DB.
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [config])
    }

    var body: some Scene {
        WindowGroup {
            if let sharedModelContainer {
                RootView()
                    .modelContainer(sharedModelContainer)
            } else {
                StorageUnavailableView()
            }
        }
    }
}

private struct StorageUnavailableView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "externaldrive.badge.exclamationmark")
                .font(.system(size: 44))
                .foregroundStyle(.orange)

            Text("Storage Unavailable")
                .font(.title3.weight(.semibold))

            Text("Pocket Postcard could not start its local data store. Try reinstalling the app or clearing app data.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}
