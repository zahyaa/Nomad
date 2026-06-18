//
//  NomadAppIntents.swift
//  Nomad
//
//  App Intents for Siri Shortcuts integration
//

import AppIntents
import SwiftUI
import SwiftData

// MARK: - Open Camera Intent
struct OpenCameraIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Camera in Pocket Postcard"
    static var description = IntentDescription("Open the camera to capture a new postcard")
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        // The app will open to the camera tab
        // This is handled by the app's scene configuration
        return .result()
    }
}

// MARK: - Show Travel Stats Intent
struct ShowTravelStatsIntent: AppIntent {
    static var title: LocalizedStringResource = "Show My Travel Stats"
    static var description = IntentDescription("Display your travel statistics and insights")
    static var openAppWhenRun: Bool = true
    
    @Dependency
    private var navigationModel: NavigationModel
    
    @MainActor
    func perform() async throws -> some IntentResult {
        // Signal the app to show stats view
        NotificationCenter.default.post(name: .showTravelStats, object: nil)
        return .result()
    }
}

// MARK: - Recent Postcards Intent
struct RecentPostcardsIntent: AppIntent {
    static var title: LocalizedStringResource = "Show Recent Postcards"
    static var description = IntentDescription("View your recently sent postcards")
    
    @Parameter(title: "Number of postcards")
    var count: Int?
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[PostcardEntity]> {
        let limit = count ?? 5
        let container = try ModelContainer(for: Postcard.self)
        let context = container.mainContext
        
        let descriptor = FetchDescriptor<Postcard>(
            predicate: #Predicate { $0.statusRaw == "sent" },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        let postcards = try context.fetch(descriptor)
        let limited = Array(postcards.prefix(limit))
        
        let entities = limited.map { postcard in
            PostcardEntity(
                id: postcard.id,
                locationName: postcard.locationName,
                timestamp: postcard.timestamp
            )
        }
        
        return .result(value: entities)
    }
}

// MARK: - Send Postcard Intent
struct SendPostcardIntent: AppIntent {
    static var title: LocalizedStringResource = "Send a Postcard"
    static var description = IntentDescription("Send a postcard to someone")
    static var openAppWhenRun: Bool = true
    
    @Parameter(title: "Recipient username")
    var recipientUsername: String?
    
    @MainActor
    func perform() async throws -> some IntentResult {
        // Open app to composer with pre-filled recipient if provided
        if let username = recipientUsername {
            NotificationCenter.default.post(
                name: .composePostcard,
                object: nil,
                userInfo: ["recipient": username]
            )
        }
        return .result()
    }
}

// MARK: - Travel Summary Intent
struct TravelSummaryIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Travel Summary"
    static var description = IntentDescription("Get a summary of your travels")
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try ModelContainer(for: Postcard.self)
        let context = container.mainContext
        
        let descriptor = FetchDescriptor<Postcard>(
            predicate: #Predicate { $0.statusRaw == "sent" }
        )
        
        let postcards = try context.fetch(descriptor)
        let uniqueLocations = Set(postcards.map { $0.locationName }).count
        let uniqueCountries = Set(postcards.compactMap { $0.countryCode }).count
        
        let summary: String
        if postcards.isEmpty {
            summary = "You haven't sent any postcards yet. Start your journey today!"
        } else {
            summary = "You've sent \(postcards.count) postcards from \(uniqueLocations) unique locations across \(uniqueCountries) countries. Keep exploring!"
        }
        
        return .result(dialog: IntentDialog(stringLiteral: summary))
    }
}

// MARK: - Create Year Review Intent
struct CreateYearReviewIntent: AppIntent {
    static var title: LocalizedStringResource = "Create Year in Review"
    static var description = IntentDescription("Generate your travel year in review")
    static var openAppWhenRun: Bool = true
    
    @Parameter(title: "Year")
    var year: Int?
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let targetYear = year ?? Calendar.current.component(.year, from: .now)
        NotificationCenter.default.post(
            name: .showYearReview,
            object: nil,
            userInfo: ["year": targetYear]
        )
        return .result()
    }
}

// MARK: - Entities
nonisolated struct PostcardEntity: Identifiable, Hashable, Sendable {
    let id: UUID
    let locationName: String
    let timestamp: Date
}

nonisolated extension PostcardEntity: AppEntity {
    nonisolated static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Postcard")
    }

    nonisolated var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(locationName)",
            subtitle: "\(timestamp.formatted(date: .abbreviated, time: .omitted))"
        )
    }

    nonisolated static var defaultQuery: PostcardQuery { PostcardQuery() }
}

struct PostcardQuery: EntityQuery {
    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [PostcardEntity] {
        let container = try ModelContainer(for: Postcard.self)
        let context = container.mainContext

        let descriptor = FetchDescriptor<Postcard>(
            predicate: #Predicate { postcard in
                identifiers.contains(postcard.id)
            }
        )

        let postcards = try context.fetch(descriptor)
        return postcards.map { PostcardEntity(id: $0.id, locationName: $0.locationName, timestamp: $0.timestamp) }
    }

    @MainActor
    func suggestedEntities() async throws -> [PostcardEntity] {
        let container = try ModelContainer(for: Postcard.self)
        let context = container.mainContext

        let descriptor = FetchDescriptor<Postcard>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        let postcards = try context.fetch(descriptor)
        let recent = Array(postcards.prefix(10))
        return recent.map { PostcardEntity(id: $0.id, locationName: $0.locationName, timestamp: $0.timestamp) }
    }
}

// MARK: - App Shortcuts
struct NomadAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenCameraIntent(),
            phrases: [
                "Open camera in \(.applicationName)",
                "Take a postcard with \(.applicationName)",
                "Capture a moment in \(.applicationName)"
            ],
            shortTitle: "Open Camera",
            systemImageName: "camera.fill"
        )
        
        AppShortcut(
            intent: ShowTravelStatsIntent(),
            phrases: [
                "Show my travel stats in \(.applicationName)",
                "My \(.applicationName) travel statistics",
                "Show my \(.applicationName) stats"
            ],
            shortTitle: "Travel Stats",
            systemImageName: "chart.bar.fill"
        )
        
        AppShortcut(
            intent: TravelSummaryIntent(),
            phrases: [
                "Get my \(.applicationName) travel summary",
                "How many postcards have I sent in \(.applicationName)",
                "My \(.applicationName) summary"
            ],
            shortTitle: "Travel Summary",
            systemImageName: "envelope.fill"
        )
        
        AppShortcut(
            intent: SendPostcardIntent(),
            phrases: [
                "Send a postcard with \(.applicationName)",
                "Send a \(.applicationName) postcard"
            ],
            shortTitle: "Send Postcard",
            systemImageName: "paperplane.fill"
        )
        
        AppShortcut(
            intent: CreateYearReviewIntent(),
            phrases: [
                "Create \(.applicationName) year in review",
                "Show my \(.applicationName) year in review"
            ],
            shortTitle: "Year Review",
            systemImageName: "calendar"
        )
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let showTravelStats = Notification.Name("showTravelStats")
    static let composePostcard = Notification.Name("composePostcard")
    static let showYearReview = Notification.Name("showYearReview")
}

// MARK: - Navigation Model (for dependency injection)
@Observable
class NavigationModel {
    var showStats = false
    var showComposer = false
    var showYearReview = false
    var composerRecipient: String?
    var yearReviewYear: Int?
}
