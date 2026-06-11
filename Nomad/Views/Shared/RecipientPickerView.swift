//
//  RecipientPickerView.swift
//  Nomad
//

import SwiftUI
import CloudKit

struct RecipientPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""
    @State private var results: [RecipientResult] = []
    @State private var isSearching = false
    @State private var error: String?

    var onSelect: (String) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TextField("Search by username", text: $query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(10)
                    .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .onChange(of: query) { _, _ in
                        Task { await debouncedSearch() }
                    }

                if isSearching {
                    ProgressView().padding()
                }

                if let error {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                List(results) { result in
                    Button {
                        onSelect(result.username)
                        dismiss()
                    } label: {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color.accentColor.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                Text(result.initial)
                                    .font(.headline)
                                    .foregroundStyle(.tint)
                            }
                            Text("@\(result.username)")
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Send to")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func debouncedSearch() async {
        let snapshot = query.lowercased()
        try? await Task.sleep(nanoseconds: 300_000_000)
        guard snapshot == query.lowercased() else { return }
        guard !snapshot.isEmpty else {
            results = []
            return
        }
        isSearching = true
        defer { isSearching = false }

        do {
            let records = try await CloudKitManager.shared.searchUsers(prefix: snapshot)
            results = records.compactMap { record in
                guard let username = record["username"] as? String else { return nil }
                return RecipientResult(username: username)
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct RecipientResult: Identifiable, Hashable {
    let username: String
    var id: String { username }
    var initial: String { String(username.prefix(1)).uppercased() }
}
