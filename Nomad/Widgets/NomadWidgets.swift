//
//  NomadWidgets.swift
//  Nomad
//
//  Widget code lives here until you move it into a real Widget Extension
//  target. Steps to ship widgets to the Home Screen / Lock Screen:
//
//    1. Xcode → File → New → Target → Widget Extension → name "NomadWidgets".
//    2. In the new target's settings, untick "Include Configuration Intent"
//       unless you need interactive config.
//    3. Move this file's *Target Membership* from the main app to the
//       NomadWidgets target (File Inspector → Target Membership).
//    4. Add `@main` back to `NomadWidgetBundle` below.
//    5. Add an App Group capability to both the main app and the widget
//       target with the same id (e.g. `group.com.yahya.Nomad`) and update
//       `WidgetStatsStore` below to use `UserDefaults(suiteName:)` so the
//       widget reads the same stats the app writes.
//
//  Until then, this file compiles as inert code so it doesn't break the
//  main build, and you can preview the widget views from this file.
//

import WidgetKit
import SwiftUI
import SwiftData
import UIKit

// MARK: - Shared snapshot cache

/// Widgets can't open the app's SwiftData store from a separate process
/// without an App Group. As a stopgap the app writes a tiny snapshot to
/// `UserDefaults` whenever a new postcard is saved, and the widget reads
/// from the same key. Replace `UserDefaults.standard` with a suite-backed
/// store once you wire up the App Group.
enum WidgetStatsStore {
    private static let key = "nomad.widget.snapshot.v1"
    private static var defaults: UserDefaults { .standard }

    struct Snapshot: Codable {
        var totalPostcards: Int
        var uniqueLocations: Int
        var recentLocation: String?
        var recentTimestamp: Date?
        var thumbnailData: Data?
    }

    static func write(_ snapshot: Snapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key)
    }

    static func read() -> Snapshot {
        guard
            let data = defaults.data(forKey: key),
            let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data)
        else {
            return Snapshot(totalPostcards: 0, uniqueLocations: 0,
                            recentLocation: nil, recentTimestamp: nil, thumbnailData: nil)
        }
        return snapshot
    }
}

// MARK: - Widget Entry

struct PostcardEntry: TimelineEntry {
    let date: Date
    let postcard: PostcardSnapshot?
    let stats: StatsSnapshot
}

struct PostcardSnapshot: Identifiable {
    let id: UUID
    let locationName: String
    let timestamp: Date
    let thumbnailData: Data?
}

struct StatsSnapshot {
    let totalPostcards: Int
    let uniqueLocations: Int
    let recentLocation: String?
}

// MARK: - Timeline Provider

struct PostcardProvider: TimelineProvider {
    func placeholder(in context: Context) -> PostcardEntry {
        PostcardEntry(
            date: Date(),
            postcard: PostcardSnapshot(
                id: UUID(),
                locationName: "San Francisco",
                timestamp: Date(),
                thumbnailData: nil
            ),
            stats: StatsSnapshot(totalPostcards: 42, uniqueLocations: 15, recentLocation: "San Francisco")
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (PostcardEntry) -> Void) {
        completion(fetchEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PostcardEntry>) -> Void) {
        let entry = fetchEntry()
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600)))
        completion(timeline)
    }

    private func fetchEntry() -> PostcardEntry {
        let snapshot = WidgetStatsStore.read()
        let postcard = snapshot.recentLocation.map { location in
            PostcardSnapshot(
                id: UUID(),
                locationName: location,
                timestamp: snapshot.recentTimestamp ?? Date(),
                thumbnailData: snapshot.thumbnailData
            )
        }
        return PostcardEntry(
            date: Date(),
            postcard: postcard,
            stats: StatsSnapshot(
                totalPostcards: snapshot.totalPostcards,
                uniqueLocations: snapshot.uniqueLocations,
                recentLocation: snapshot.recentLocation
            )
        )
    }
}

// MARK: - Small Widget

struct SmallPostcardWidget: View {
    let entry: PostcardEntry

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "envelope.fill")
                .font(.title2)
                .foregroundStyle(.tint)

            Text("\(entry.stats.totalPostcards)")
                .font(.title.bold())

            Text("postcards")
                .font(.caption2)
                .foregroundStyle(.secondary)

            if let location = entry.stats.recentLocation {
                Text(location)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Medium Widget

struct MediumPostcardWidget: View {
    let entry: PostcardEntry

    var body: some View {
        HStack(spacing: 16) {
            thumbnail
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 8) {
                if let postcard = entry.postcard {
                    Text(postcard.locationName)
                        .font(.headline)
                        .lineLimit(1)

                    Text(postcard.timestamp.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 16) {
                    StatColumn(value: entry.stats.totalPostcards, label: "postcards")
                    StatColumn(value: entry.stats.uniqueLocations, label: "places")
                }
            }

            Spacer()
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let data = entry.postcard?.thumbnailData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(.tint.opacity(0.2))
                .overlay {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                }
        }
    }
}

private struct StatColumn: View {
    let value: Int
    let label: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)").font(.title3.bold())
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }
}

// MARK: - Large Widget

struct LargePostcardWidget: View {
    let entry: PostcardEntry

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "envelope.fill")
                    .font(.title2)
                    .foregroundStyle(.tint)
                Text("Recent Postcards")
                    .font(.headline)
                Spacer()
            }

            if let postcard = entry.postcard,
               let imageData = postcard.thumbnailData,
               let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    Text(postcard.locationName)
                        .font(.headline)
                    Text(postcard.timestamp.formatted(date: .long, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.tint.opacity(0.2))
                    .frame(height: 200)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.stack")
                                .font(.system(size: 48))
                                .foregroundStyle(.tertiary)
                            Text("No postcards yet")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
            }

            HStack(spacing: 24) {
                StatLabel(value: entry.stats.totalPostcards, label: "Postcards", icon: "envelope.fill")
                StatLabel(value: entry.stats.uniqueLocations, label: "Places", icon: "mappin.circle.fill")
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct StatLabel: View {
    let value: Int
    let label: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(value)")
                    .font(.title3.bold())
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Lock Screen Widgets

/// `accessoryCircular` is constrained to ~50pt — text must be a single number.
struct LockScreenCircularWidget: View {
    let entry: PostcardEntry

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "envelope.fill")
                .font(.caption2)
            Text("\(entry.stats.totalPostcards)")
                .font(.title3.bold())
                .minimumScaleFactor(0.6)
        }
        .containerBackground(.clear, for: .widget)
    }
}

/// `accessoryRectangular` is the wider lock-screen tile — fits a few lines.
struct LockScreenRectangularWidget: View {
    let entry: PostcardEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let postcard = entry.postcard {
                Text(postcard.locationName)
                    .font(.caption.bold())
                    .lineLimit(1)
            } else {
                Text("No postcards yet")
                    .font(.caption.bold())
            }
            HStack(spacing: 12) {
                Label("\(entry.stats.totalPostcards)", systemImage: "envelope.fill")
                    .font(.caption2)
                Label("\(entry.stats.uniqueLocations)", systemImage: "mappin.circle.fill")
                    .font(.caption2)
            }
        }
        .containerBackground(.clear, for: .widget)
    }
}

// MARK: - Widget Definitions

struct NomadSmallWidget: Widget {
    let kind: String = "NomadSmallWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PostcardProvider()) { entry in
            SmallPostcardWidget(entry: entry)
        }
        .configurationDisplayName("Postcard Stats")
        .description("See your postcard count and recent location.")
        .supportedFamilies([.systemSmall])
    }
}

struct NomadMediumWidget: Widget {
    let kind: String = "NomadMediumWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PostcardProvider()) { entry in
            MediumPostcardWidget(entry: entry)
        }
        .configurationDisplayName("Latest Postcard")
        .description("Your most recent postcard and stats.")
        .supportedFamilies([.systemMedium])
    }
}

struct NomadLargeWidget: Widget {
    let kind: String = "NomadLargeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PostcardProvider()) { entry in
            LargePostcardWidget(entry: entry)
        }
        .configurationDisplayName("Postcard Gallery")
        .description("Featured postcard with your travel stats.")
        .supportedFamilies([.systemLarge])
    }
}

struct NomadLockScreenCircularWidget: Widget {
    let kind: String = "NomadLockScreenCircular"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PostcardProvider()) { entry in
            LockScreenCircularWidget(entry: entry)
        }
        .configurationDisplayName("Postcards Count")
        .description("Your total postcard count.")
        .supportedFamilies([.accessoryCircular])
    }
}

struct NomadLockScreenRectangularWidget: Widget {
    let kind: String = "NomadLockScreenRectangular"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PostcardProvider()) { entry in
            LockScreenRectangularWidget(entry: entry)
        }
        .configurationDisplayName("Latest Postcard")
        .description("Your most recent postcard at a glance.")
        .supportedFamilies([.accessoryRectangular])
    }
}

// MARK: - Widget Bundle
//
// Re-enable `@main` once this file lives in its own Widget Extension target.
// Leaving it off in the main app target avoids the duplicate-`@main` linker
// error with `NomadApp`.
//
// @main
struct NomadWidgetBundle: WidgetBundle {
    var body: some Widget {
        NomadSmallWidget()
        NomadMediumWidget()
        NomadLargeWidget()
        NomadLockScreenCircularWidget()
        NomadLockScreenRectangularWidget()
    }
}
