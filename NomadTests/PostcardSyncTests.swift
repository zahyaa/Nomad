//
//  PostcardSyncTests.swift
//  NomadTests
//

import Testing
import Foundation
import SwiftData
@testable import Nomad

@MainActor
struct PostcardSyncTests {

    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Postcard.self, User.self, configurations: config)
        return container.mainContext
    }

    @Test func ingestEmptyArrayReturnsZero() async throws {
        let ctx = try makeContext()
        let added = await PostcardSync.ingest(records: [], into: ctx)
        #expect(added == 0)

        let stored = try ctx.fetch(FetchDescriptor<Postcard>())
        #expect(stored.isEmpty)
    }
}
