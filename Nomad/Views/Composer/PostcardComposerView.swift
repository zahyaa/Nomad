//
//  PostcardComposerView.swift
//  Nomad
//

import SwiftUI
import SwiftData
import UIKit

struct PostcardComposerView: View {
    @Bindable var postcard: Postcard
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var draftMessage: String = ""
    @State private var renderedImage: UIImage?
    @State private var showRecipientPicker = false
    @State private var isSending = false
    @State private var sendError: String?
    @State private var sendSucceeded = false
    @State private var isSuggesting = false
    @State private var suggestionError: String?
    @State private var isRendering = false
    @State private var isSavingToPhotos = false
    @State private var saveToPhotosError: String?
    @State private var saveToPhotosSuccess = false
    @State private var isValidatingRecipient = false
    @State private var recipientValidationError: String?

    private let maxMessageLength = 120
    @Namespace private var sendNamespace

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    if !sendSucceeded {
                        PostcardView(postcard: postcard)
                            .matchedGeometryEffect(id: "postcard", in: sendNamespace)
                            .padding(.horizontal)
                    } else {
                        flyAwayView
                    }
                    messageEditor
                    fontStylePicker
                    recipientSection
                    actionButtons
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("New Postcard")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showRecipientPicker) {
            RecipientPickerView { username in
                postcard.recipientUsername = username
                try? modelContext.save()
            }
        }
        .alert("Send failed", isPresented: Binding(
            get: { sendError != nil },
            set: { if !$0 { sendError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(sendError ?? "")
        }
        .onAppear {
            draftMessage = postcard.message ?? ""
        }
    }

    @ViewBuilder
    private var flyAwayView: some View {
        PostcardView(postcard: postcard)
            .matchedGeometryEffect(id: "postcard", in: sendNamespace)
            .padding(.horizontal)
            .offset(y: -120)
            .opacity(0)
            .animation(.easeInOut(duration: 0.6), value: sendSucceeded)
            .overlay {
                VStack(spacing: 12) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.tint)
                    Text("Sent!")
                        .font(.title2.bold())
                }
                .padding(.top, 40)
            }
    }

    private var messageEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Message")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if case .ready = PostcardMessageGenerator.status() {
                    Button {
                        Task { await suggestMessage() }
                    } label: {
                        if isSuggesting {
                            ProgressView().controlSize(.mini)
                        } else {
                            Label("Suggest", systemImage: "sparkles")
                                .labelStyle(.titleAndIcon)
                                .font(.caption.weight(.semibold))
                        }
                    }
                    .buttonStyle(.glass)
                    .disabled(isSuggesting)
                }
            }
            TextField("Wish you were here…", text: $draftMessage, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(.roundedBorder)
                .onChange(of: draftMessage) { _, newValue in
                    if newValue.count > maxMessageLength {
                        draftMessage = String(newValue.prefix(maxMessageLength))
                    }
                    postcard.message = draftMessage.isEmpty ? nil : draftMessage
                    try? modelContext.save()
                }
            
            // Quick message templates
            if draftMessage.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(MessageTemplate.allCases, id: \.self) { template in
                            Button {
                                draftMessage = template.text
                                postcard.message = draftMessage
                                try? modelContext.save()
                            } label: {
                                Text(template.text)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.tint.opacity(0.1), in: Capsule())
                                    .foregroundStyle(.tint)
                            }
                        }
                    }
                }
            }
            
            HStack {
                if let suggestionError {
                    Text(suggestionError)
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
                Spacer()
                Text("\(draftMessage.count) / \(maxMessageLength)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
    }

    private func suggestMessage() async {
        isSuggesting = true
        suggestionError = nil
        defer { isSuggesting = false }
        do {
            let suggestion = try await PostcardMessageGenerator.suggest(for: postcard)
            draftMessage = String(suggestion.prefix(maxMessageLength))
            postcard.message = draftMessage
            try? modelContext.save()
        } catch {
            suggestionError = "Couldn't generate a suggestion."
        }
    }

    private var fontStylePicker: some View {
        Picker("Font", selection: Binding(
            get: { postcard.fontStyle },
            set: {
                postcard.fontStyle = $0
                try? modelContext.save()
            }
        )) {
            ForEach(PostcardFontStyle.allCases) { style in
                Text(style.label).tag(style)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }

    private var recipientSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Send to")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Button {
                showRecipientPicker = true
            } label: {
                HStack {
                    Image(systemName: "person.crop.circle")
                    VStack(alignment: .leading, spacing: 2) {
                        Text(postcard.recipientUsername.map { "@\($0)" } ?? "Choose a Nomad")
                            .foregroundStyle(postcard.recipientUsername == nil ? Color.secondary : Color.primary)
                        if isValidatingRecipient {
                            HStack(spacing: 4) {
                                ProgressView().controlSize(.mini)
                                Text("Checking…")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        } else if let error = recipientValidationError {
                            Text(error)
                                .font(.caption2)
                                .foregroundStyle(.red)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.background, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .onChange(of: postcard.recipientUsername) { _, newValue in
            if let username = newValue {
                Task { await validateRecipient(username) }
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if let image = renderedImage ?? cachedRenderedImage {
                HStack(spacing: 12) {
                    Button {
                        Task { await saveToPhotos(image) }
                    } label: {
                        HStack {
                            if isSavingToPhotos {
                                ProgressView().controlSize(.small)
                            } else if saveToPhotosSuccess {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else {
                                Image(systemName: "square.and.arrow.down")
                            }
                            Text(saveToPhotosSuccess ? "Saved" : "Save to Photos")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.glass)
                    .disabled(isSavingToPhotos || saveToPhotosSuccess)
                    
                    ShareLink(
                        item: Image(uiImage: image),
                        preview: SharePreview(
                            "Postcard from \(postcard.locationName)",
                            image: Image(uiImage: image)
                        )
                    ) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.glass)
                }
            } else {
                Button {
                    Task { await renderPostcard() }
                } label: {
                    HStack {
                        if isRendering {
                            ProgressView().controlSize(.small)
                        }
                        Text(isRendering ? "Rendering…" : "Prepare to Share")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.glass)
                .disabled(isRendering)
            }

            Button {
                Task { await send() }
            } label: {
                HStack {
                    if isSending {
                        ProgressView().tint(.white)
                    }
                    Text(isSending ? "Sending…" : "Send via Nomad")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.glassProminent)
            .disabled(postcard.recipientUsername == nil || 
                     isSending || 
                     isValidatingRecipient || 
                     recipientValidationError != nil)
        }
        .padding(.horizontal)
        .alert("Couldn't save to Photos", isPresented: Binding(
            get: { saveToPhotosError != nil },
            set: { if !$0 { saveToPhotosError = nil } }
        )) {
            Button("OK", role: .cancel) {}
            if saveToPhotosError?.contains("denied") == true {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        } message: {
            Text(saveToPhotosError ?? "")
        }
    }
    
    private func renderPostcard() async {
        isRendering = true
        defer { isRendering = false }
        
        if let image = await PostcardRenderer.renderInBackground(postcard) {
            renderedImage = image
            if let data = image.pngData() {
                postcard.renderedImageData = data
            }
            try? modelContext.save()
        }
    }
    
    private func saveToPhotos(_ image: UIImage) async {
        isSavingToPhotos = true
        saveToPhotosError = nil
        defer { isSavingToPhotos = false }
        
        do {
            try await PhotoLibraryManager.saveImage(image)
            saveToPhotosSuccess = true
            
            let notify = UINotificationFeedbackGenerator()
            notify.notificationOccurred(.success)
        } catch {
            saveToPhotosError = error.localizedDescription
        }
    }
    
    private func validateRecipient(_ username: String) async {
        isValidatingRecipient = true
        recipientValidationError = nil
        defer { isValidatingRecipient = false }
        
        do {
            let userRecord = try await CloudKitManager.shared.findUser(username: username)
            if userRecord == nil {
                recipientValidationError = "User not found"
            }
        } catch {
            recipientValidationError = "Couldn't verify user"
        }
    }

    private var cachedRenderedImage: UIImage? {
        guard let data = postcard.renderedImageData else { return nil }
        return UIImage(data: data)
    }

    private func send() async {
        guard let recipient = postcard.recipientUsername else { return }
        isSending = true
        defer { isSending = false }

        // Render in background if not already rendered
        if postcard.renderedImageData == nil {
            if let image = await PostcardRenderer.renderInBackground(postcard) {
                renderedImage = image
                if let data = image.pngData() {
                    postcard.renderedImageData = data
                }
            }
        }

        do {
            try await CloudKitManager.shared.sendPostcard(postcard, to: recipient)
            postcard.status = .sent
            try? modelContext.save()

            let notify = UINotificationFeedbackGenerator()
            notify.notificationOccurred(.success)

            withAnimation(.easeInOut(duration: 0.6)) {
                sendSucceeded = true
            }
            try? await Task.sleep(nanoseconds: 900_000_000)
            dismiss()
        } catch {
            sendError = error.localizedDescription
            let notify = UINotificationFeedbackGenerator()
            notify.notificationOccurred(.error)
        }
    }
}

enum MessageTemplate: String, CaseIterable {
    case wishYouWereHere = "Wish you were here!"
    case greetings = "Greetings from paradise!"
    case thinkingOfYou = "Thinking of you from afar"
    case beautifulPlace = "What a beautiful place!"
    case amazingView = "The view here is incredible"
    case missYou = "Missing you from here"
    case havingGreatTime = "Having an amazing time!"
    case soGrateful = "Feeling so grateful right now"
    
    var text: String {
        return rawValue
    }
}
