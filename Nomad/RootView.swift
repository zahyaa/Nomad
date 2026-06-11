//
//  RootView.swift
//  Nomad
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Query private var users: [User]
    @AppStorage("nomad.onboardingComplete") private var onboardingComplete = false

    var body: some View {
        // Two gates: a `User` row in SwiftData proves the auth flow finished,
        // and the AppStorage flag lets `signOut()` return the user to onboarding
        // without deleting their row. Either condition off → show onboarding.
        if users.isEmpty || !onboardingComplete {
            OnboardingView()
        } else {
            MainTabView()
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @State private var mailboxBadge: Int = 0
    @State private var subscriptionReady = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView(selection: $selectedTab) {
            CameraTabView()
                .tabItem { Label("Capture", systemImage: "camera.fill") }
                .tag(0)

            HistoryView()
                .tabItem { Label("Sent", systemImage: "paperplane.fill") }
                .tag(1)

            MailboxView(badgeCount: $mailboxBadge)
                .tabItem { Label("Mailbox", systemImage: "tray.fill") }
                .badge(mailboxBadge)
                .tag(2)
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .task {
            await CloudKitManager.shared.ensureReceiveSubscription()
            subscriptionReady = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NomadAppDelegate.didReceivePostcardNotification)) { _ in
            guard subscriptionReady else { return }
            Task { await handleIncoming() }
        }
    }

    private func handleIncoming() async {
        do {
            let records = try await CloudKitManager.shared.fetchReceivedPostcards()
            let added = await PostcardSync.ingest(records: records, into: modelContext)
            if added > 0 {
                mailboxBadge += added
            }
        } catch {
            // silent: user can pull-to-refresh in the mailbox
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [Postcard.self, User.self], inMemory: true)
}
