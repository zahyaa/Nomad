//
//  MailboxView.swift
//  Nomad
//

import SwiftUI
import SwiftData
import CloudKit
import UIKit

struct MailboxView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var badgeCount: Int
    @Query(
        filter: #Predicate<Postcard> { $0.statusRaw == "received" },
        sort: [SortDescriptor(\Postcard.timestamp, order: .reverse)]
    ) private var receivedPostcards: [Postcard]

    @State private var isRefreshing = false
    @State private var error: String?
    @State private var hasAppeared = false

    var body: some View {
        NavigationStack {
            Group {
                if receivedPostcards.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(receivedPostcards) { card in
                            NavigationLink {
                                PostcardDetailScreen(postcard: card)
                            } label: {
                                PostcardRowView(postcard: card)
                            }
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Mailbox")
            .refreshable { await refresh() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isRefreshing)
                }
            }
            .task {
                await refresh()
            }
            .onAppear {
                // Only reset badge on first appear, not on every tab switch
                if !hasAppeared {
                    badgeCount = 0
                    hasAppeared = true
                }
            }
            .alert("Couldn't refresh", isPresented: Binding(
                get: { error != nil },
                set: { if !$0 { error = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(error ?? "")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "envelope.open")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)
            Text("No Postcards Yet")
                .font(.title2.weight(.semibold))
            Text("When friends send you postcards, they'll appear here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding()
    }

    @MainActor
    private func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let records = try await CloudKitManager.shared.fetchReceivedPostcards()
            let newCount = await PostcardSync.ingest(records: records, into: modelContext)
            if newCount > 0 {
                badgeCount = max(0, badgeCount - newCount)
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(receivedPostcards[index])
        }
        try? modelContext.save()
    }
}

enum PostcardSync {
    /// Inserts records into Swift Data, skipping ones we already have. Returns
    /// the number of newly inserted postcards.
    @MainActor
    @discardableResult
    static func ingest(records: [CKRecord], into context: ModelContext) async -> Int {
        var added = 0
        for record in records {
            let recordName = record.recordID.recordName
            let key = "ck.\(recordName)"
            if UserDefaults.standard.bool(forKey: key) { continue }

            guard
                let locationName = record["locationName"] as? String,
                let lat = record["latitude"] as? Double,
                let lon = record["longitude"] as? Double,
                let sender = record["senderUsername"] as? String,
                let recipient = record["recipientUsername"] as? String,
                let sentAt = record["sentAt"] as? Date,
                let asset = record["postcardImage"] as? CKAsset,
                let assetURL = asset.fileURL,
                let data = try? Data(contentsOf: assetURL)
            else { continue }

            let message = record["message"] as? String
            let stampTheme = (record["stampTheme"] as? String) ?? "city"

            // Compress the image data to ensure consistent format and size limits
            guard let compressedData = ImageCompressor.compress(data) else { continue }

            // Only store rawImageData; renderedImageData will be generated on-demand
            // to avoid doubling memory usage for large images
            let postcard = Postcard(
                rawImageData: compressedData,
                locationName: locationName,
                latitude: lat,
                longitude: lon,
                timestamp: sentAt,
                message: message,
                stampTheme: stampTheme,
                status: .received,
                recipientUsername: recipient,
                senderUsername: sender
            )
            context.insert(postcard)
            UserDefaults.standard.set(true, forKey: key)
            added += 1
        }
        try? context.save()
        return added
    }
}
