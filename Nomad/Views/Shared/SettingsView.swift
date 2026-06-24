//
//  SettingsView.swift
//  Nomad
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Bindable var settings = UserSettings.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var users: [User]
    @Query private var postcards: [Postcard]

    @AppStorage("nomad.onboardingComplete") private var onboardingComplete = false
    @AppStorage("nomad.cloudKitEnabled") private var cloudKitEnabled = true

    @State private var showSignOutConfirm = false
    @State private var showDeleteConfirm = false

    private var currentUsername: String? {
        users.first?.username
    }

    var body: some View {
        NavigationStack {
            Form {
                accountSection
                cameraSection
                syncSection
                aboutSection
                dangerZoneSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog(
                "Sign out of Pocket Postcard?",
                isPresented: $showSignOutConfirm,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) { signOut() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You'll keep your postcards locally and can sign in again any time.")
            }
            .confirmationDialog(
                "Delete your account?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete Account", role: .destructive) { deleteAccount() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently removes your username, profile, and every postcard on this device. This can't be undone.")
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var accountSection: some View {
        Section {
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 2) {
                    if let username = currentUsername {
                        Text("@\(username)")
                            .font(.headline)
                    } else {
                        Text("Signed in")
                            .font(.headline)
                    }
                    Text("Signed in with Apple")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Account")
        }
    }

    @ViewBuilder
    private var cameraSection: some View {
        Section {
            Picker("Photo Quality", selection: $settings.photoQuality) {
                ForEach(PhotoQuality.allCases, id: \.self) { quality in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(quality.rawValue)
                        Text(qualityDescription(quality))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .tag(quality)
                }
            }
            .pickerStyle(.inline)
        } header: {
            Text("Camera")
        } footer: {
            Text("Higher quality produces larger file sizes. Medium quality is recommended for most users.")
        }
    }

    @ViewBuilder
    private var syncSection: some View {
        Section {
            Toggle("Sync via iCloud", isOn: Binding(
                get: { cloudKitEnabled },
                set: { newValue in
                    cloudKitEnabled = newValue
                    if newValue {
                        CloudKitManager.shared.enable()
                        // First-time enable: backfill the UserRecord that
                        // sign-in skipped because Sync was off, then
                        // register the receive subscription.
                        Task {
                            await CloudKitManager.shared.upsertCurrentUserIfNeeded()
                            await CloudKitManager.shared.ensureReceiveSubscription()
                        }
                    } else {
                        CloudKitManager.shared.disableForTesting()
                    }
                }
            ))
        } header: {
            Text("Sync")
        } footer: {
            Text("Turn on to send and receive postcards via iCloud. Requires an iCloud account and a deployed CloudKit schema. Leave off to use Pocket Postcard fully offline (share to Messages still works).")
        }
    }

    @ViewBuilder
    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text(versionString)
                    .foregroundStyle(.secondary)
            }
            Link(destination: URL(string: "https://winglet-space.co/nomad/privacy")!) {
                HStack {
                    Text("Privacy Policy")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("About")
        }
    }

    @ViewBuilder
    private var dangerZoneSection: some View {
        Section {
            Button {
                showSignOutConfirm = true
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
            }

            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("Delete Account", systemImage: "trash")
            }
        } header: {
            Text("Account Actions")
        } footer: {
            Text("Signing out keeps your postcards. Deleting your account removes everything from this device.")
        }
    }

    // MARK: - Helpers

    private var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }

    private func qualityDescription(_ quality: PhotoQuality) -> String {
        switch quality {
        case .high:
            return "Best quality, ~3-5 MB per photo"
        case .medium:
            return "Balanced quality, ~2-3 MB per photo"
        case .low:
            return "Smaller files, ~1-2 MB per photo"
        }
    }

    private func signOut() {
        // Sign Out: reversible. Keeps the User row and every postcard intact
        // so re-signing in with the same Apple ID resumes the account.
        // We only flip the onboarding flag and clear the cached username so
        // CloudKit queries don't keep targeting a "signed-out" identity.
        CloudKitManager.shared.setCurrentUsername("")
        UserDefaults.standard.removeObject(forKey: "nomad.currentUsername")
        onboardingComplete = false
        dismiss()
    }

    private func deleteAccount() {
        // Delete Account: destructive, App Store guideline 5.1.1(v) compliance.
        // Removes User + every Postcard from the local store, wipes
        // identifying UserDefaults, and purges the CloudKit UserRecord.
        for user in users {
            modelContext.delete(user)
        }
        for card in postcards {
            modelContext.delete(card)
        }
        try? modelContext.save()
        UserDefaults.standard.removeObject(forKey: "nomad.currentUsername")
        // Fire-and-forget — failures are logged by CloudKitManager.
        Task { await CloudKitManager.shared.deleteCurrentUserRecord() }
        onboardingComplete = false
        dismiss()
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Postcard.self, User.self], inMemory: true)
}
