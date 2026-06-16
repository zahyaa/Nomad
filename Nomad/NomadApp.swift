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

    let sharedModelContainer: ModelContainer = {
        let schema = Schema([Postcard.self, User.self, PostcardCollection.self, CustomStamp.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Most often this fires when the on-disk schema is incompatible
            // with the current model. Fall back to an in-memory store so the
            // app still launches instead of trapping in `.modelContainer(for:)`.
            Log.storage.error("Falling back to in-memory store: \(error.localizedDescription, privacy: .public)")
            let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: [memoryConfig])
            } catch {
                fatalError("Unable to create ModelContainer even in memory: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
