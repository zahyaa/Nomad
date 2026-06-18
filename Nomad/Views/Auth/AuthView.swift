//
//  AuthView.swift
//  Nomad
//

import SwiftUI
import SwiftData
import AuthenticationServices

struct AuthView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var appleUserID: String?
    @State private var suggestedName: String = ""
    @State private var username: String = ""
    @State private var error: String?
    @State private var isCheckingUsername = false
    @State private var isUsernameAvailable: Bool?
    @State private var searchTask: Task<Void, Never>?
    @State private var validationError: UsernameValidator.ValidationError?

    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "envelope.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("Welcome to Nomad")
                .font(.largeTitle.bold())
            Text("Sign in with Apple to send and receive postcards.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if appleUserID == nil {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    handleSignIn(result)
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .padding(.horizontal, 40)

                #if DEBUG
                Button {
                    useTestAccount()
                } label: {
                    Label("Continue as test user", systemImage: "person.crop.circle.badge.questionmark")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.glass)
                .padding(.horizontal, 40)
                .padding(.top, 4)

                Text("Skips Sign in with Apple and CloudKit for local testing.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                #endif
            } else {
                usernameForm
            }

            if let error {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            Spacer()
        }
        .padding()
    }

    private var usernameForm: some View {
        VStack(spacing: 12) {
            Text("Choose a username")
                .font(.headline)
            TextField("nomad_username", text: $username)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 40)
                .onChange(of: username) { _, newValue in
                    let cleaned = newValue
                        .lowercased()
                        .filter { $0.isLetter || $0.isNumber || $0 == "_" }
                    if cleaned != newValue { username = cleaned }
                    isUsernameAvailable = nil
                    validationError = UsernameValidator.validate(cleaned)
                }

            HStack(spacing: 6) {
                if let validationError {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                    Text(validationError.errorDescription ?? "Invalid username")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if isCheckingUsername {
                    ProgressView().controlSize(.small)
                } else if let available = isUsernameAvailable {
                    Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(available ? .green : .red)
                    Text(available ? "Available" : "Taken")
                        .font(.caption)
                }
            }
            .frame(height: 16)

            Button {
                Task { await commit() }
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.glassProminent)
            .padding(.horizontal, 40)
            .disabled(validationError != nil || isCheckingUsername || username.isEmpty)
            .onChange(of: username) { _, _ in
                searchTask?.cancel()
                searchTask = Task { await debouncedCheck() }
            }
        }
    }

    private func handleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            if let cred = auth.credential as? ASAuthorizationAppleIDCredential {
                appleUserID = cred.user
                if let given = cred.fullName?.givenName, !given.isEmpty {
                    suggestedName = given.lowercased()
                    username = suggestedName
                }
            }
        case .failure(let err):
            error = err.localizedDescription
        }
    }

    private func debouncedCheck() async {
        let snapshot = username
        try? await Task.sleep(nanoseconds: 350_000_000)
        // Skip the remote check entirely if the name fails client validation —
        // saves a CloudKit round-trip on names we already know will be rejected.
        guard snapshot == username, UsernameValidator.isValid(snapshot) else { return }
        isCheckingUsername = true
        defer { isCheckingUsername = false }
        do {
            isUsernameAvailable = try await CloudKitManager.shared.isUsernameAvailable(snapshot)
        } catch {
            isUsernameAvailable = nil
        }
    }

    #if DEBUG
    private func useTestAccount() {
        let testID = "TEST-\(UUID().uuidString.prefix(8))"
        let testUsername = "test_\(Int.random(in: 1000...9999))"
        let user = User(id: testID, username: testUsername)
        modelContext.insert(user)
        try? modelContext.save()
        CloudKitManager.shared.disableForTesting()
        CloudKitManager.shared.setCurrentUsername(testUsername)
        onComplete()
    }
    #endif

    private func commit() async {
        guard let appleUserID, !username.isEmpty else { return }
        do {
            let available = try await CloudKitManager.shared.isUsernameAvailable(username)
            guard available else {
                error = "That username is taken — try another."
                isUsernameAvailable = false
                return
            }
            // Only round-trip to CloudKit when Sync is enabled. When it
            // isn't, the user can still finish onboarding locally and
            // flip "Sync via iCloud" on later — the toggle backfills the
            // UserRecord via `upsertCurrentUserIfNeeded`.
            if CloudKitManager.shared.isEnabled {
                _ = try await CloudKitManager.shared.upsertUserRecord(
                    appleUserID: appleUserID,
                    username: username,
                    avatar: nil
                )
                await CloudKitManager.shared.ensureReceiveSubscription()
            }
            let user = User(id: appleUserID, username: username)
            modelContext.insert(user)
            try? modelContext.save()
            CloudKitManager.shared.setCurrentUsername(username)
            CloudKitManager.shared.setPendingAppleUserID(appleUserID)
            onComplete()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
