//
//  SocialFeaturesView.swift
//  Nomad
//
//  Optional social features for community engagement
//

import SwiftUI
import SwiftData
import CloudKit

// MARK: - Public Share Link
struct ShareableCollectionLink {
    let collectionID: UUID
    let shareURL: URL
    let expirationDate: Date
}

// MARK: - Social Share Manager
@Observable
@MainActor
class SocialShareManager {
    var shareLinks: [UUID: ShareableCollectionLink] = [:]
    var isCreatingLink = false
    var error: Error?
    
    private let container = CKContainer(identifier: "iCloud.com.nomad.app")
    
    /// Create a public share link for a collection
    func createShareLink(for collection: PostcardCollection) async throws -> ShareableCollectionLink {
        isCreatingLink = true
        defer { isCreatingLink = false }
        
        // Create CKShare for the collection
        let database = container.publicCloudDatabase
        
        // Create a record for the collection
        let record = CKRecord(recordType: "SharedCollection")
        record["name"] = collection.name as CKRecordValue
        record["description"] = (collection.desc ?? "") as CKRecordValue
        record["createdAt"] = collection.createdAt as CKRecordValue
        record["postcardCount"] = (collection.postcards?.count ?? 0) as CKRecordValue
        
        // Save the record
        let savedRecord = try await database.save(record)
        
        // Create share URL
        let shareURL = URL(string: "nomad://collection/\(collection.id.uuidString)")!
        let expirationDate = Calendar.current.date(byAdding: .day, value: 30, to: .now)!
        
        let shareLink = ShareableCollectionLink(
            collectionID: collection.id,
            shareURL: shareURL,
            expirationDate: expirationDate
        )
        
        shareLinks[collection.id] = shareLink
        return shareLink
    }
    
    /// Revoke a share link
    func revokeShareLink(for collectionID: UUID) async {
        shareLinks.removeValue(forKey: collectionID)
        // In production, also delete the CKRecord from CloudKit
    }
}

// MARK: - Community Feed View (Optional)
struct CommunityFeedView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var feedManager = CommunityFeedManager()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if feedManager.isLoading {
                        ProgressView("Loading community feed...")
                            .padding()
                    } else if feedManager.posts.isEmpty {
                        emptyState
                    } else {
                        ForEach(feedManager.posts) { post in
                            CommunityPostCard(post: post)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Community")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .refreshable {
                await feedManager.refresh()
            }
            .task {
                await feedManager.loadPosts()
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)
            Text("No Community Posts Yet")
                .font(.title2.weight(.semibold))
            Text("Be the first to share your collection with the community!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding()
    }
}

// MARK: - Community Post
struct CommunityPost: Identifiable {
    let id: UUID
    let username: String
    let locationName: String
    let collectionName: String?
    let postcardCount: Int
    let timestamp: Date
    let thumbnailData: Data?
    var reactions: [String: Int] = [:] // emoji: count
}

// MARK: - Community Post Card
struct CommunityPostCard: View {
    let post: CommunityPost
    @State private var hasReacted = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Text(post.username.prefix(1).uppercased())
                            .font(.headline)
                            .foregroundStyle(.tint)
                    }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.username)
                        .font(.headline)
                    
                    Text(post.timestamp.formatted(.relative(presentation: .named)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            // Content
            if let thumbnailData = post.thumbnailData,
               let image = UIImage(data: thumbnailData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if let collectionName = post.collectionName {
                    Text(collectionName)
                        .font(.headline)
                }
                
                Text("Sent from \(post.locationName) • \(post.postcardCount) postcards")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Reactions
            HStack(spacing: 16) {
                ForEach(Array(post.reactions.keys.sorted()), id: \.self) { emoji in
                    if let count = post.reactions[emoji] {
                        Button {
                            hasReacted.toggle()
                        } label: {
                            HStack(spacing: 4) {
                                Text(emoji)
                                Text("\(count)")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(hasReacted ? Color.accentColor.opacity(0.2) : Color(uiColor: .secondarySystemGroupedBackground))
                            .clipShape(Capsule())
                        }
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Community Feed Manager
@Observable
@MainActor
class CommunityFeedManager {
    var posts: [CommunityPost] = []
    var isLoading = false
    var error: Error?
    
    func loadPosts() async {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate fetching from CloudKit
        try? await Task.sleep(for: .seconds(1))
        
        // In production, fetch from CloudKit public database
        // For now, return empty array
        posts = []
    }
    
    func refresh() async {
        await loadPosts()
    }
}

// MARK: - Share Collection View
struct ShareCollectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var shareManager = SocialShareManager()
    let collection: PostcardCollection
    
    @State private var shareLink: ShareableCollectionLink?
    @State private var privacyLevel: PrivacyLevel = .friendsOnly
    @State private var showCopyConfirmation = false
    
    enum PrivacyLevel: String, CaseIterable {
        case friendsOnly = "Friends Only"
        case `public` = "Public"
        case unlisted = "Unlisted (Anyone with link)"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text(collection.name)
                            .font(.headline)
                        Spacer()
                        Text("\(collection.postcards?.count ?? 0) postcards")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Collection")
                }
                
                Section {
                    Picker("Who can see this", selection: $privacyLevel) {
                        ForEach(PrivacyLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                } header: {
                    Text("Privacy")
                } footer: {
                    Text(privacyFooter)
                }
                
                Section {
                    if let link = shareLink {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Share Link")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            HStack {
                                Text(link.shareURL.absoluteString)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                
                                Spacer()
                                
                                Button {
                                    UIPasteboard.general.string = link.shareURL.absoluteString
                                    showCopyConfirmation = true
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                }
                            }
                            
                            Text("Expires \(link.expirationDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        
                        Button(role: .destructive) {
                            Task {
                                await shareManager.revokeShareLink(for: collection.id)
                                shareLink = nil
                            }
                        } label: {
                            Text("Revoke Link")
                        }
                    } else {
                        Button {
                            Task {
                                do {
                                    shareLink = try await shareManager.createShareLink(for: collection)
                                } catch {
                                    print("Failed to create share link: \(error)")
                                }
                            }
                        } label: {
                            if shareManager.isCreatingLink {
                                HStack {
                                    ProgressView()
                                    Text("Creating link...")
                                }
                            } else {
                                Label("Create Share Link", systemImage: "link")
                            }
                        }
                        .disabled(shareManager.isCreatingLink)
                    }
                } header: {
                    Text("Share")
                }
            }
            .navigationTitle("Share Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Link Copied", isPresented: $showCopyConfirmation) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Share link copied to clipboard")
            }
        }
    }
    
    private var privacyFooter: String {
        switch privacyLevel {
        case .friendsOnly:
            return "Only people you've sent postcards to can see this collection"
        case .`public`:
            return "Anyone can discover and view this collection"
        case .unlisted:
            return "Only people with the link can access this collection"
        }
    }
}

#Preview {
    CommunityFeedView()
}
