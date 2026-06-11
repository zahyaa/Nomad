//
//  PostcardMessageGenerator.swift
//  Nomad
//
//  Uses the on-device system language model (FoundationModels) to suggest a
//  postcard caption from the postcard's location and timestamp. The model
//  availability is checked first so behavior degrades gracefully on devices
//  without Apple Intelligence.
//

import Foundation
import FoundationModels

enum PostcardMessageGenerator {
    enum GenerationStatus {
        case unavailable(String)
        case ready
    }

    static func status() -> GenerationStatus {
        switch SystemLanguageModel.default.availability {
        case .available:
            return .ready
        case .unavailable(.deviceNotEligible):
            return .unavailable("This device doesn't support on-device AI.")
        case .unavailable(.appleIntelligenceNotEnabled):
            return .unavailable("Turn on Apple Intelligence in Settings.")
        case .unavailable(.modelNotReady):
            return .unavailable("The model is still downloading.")
        case .unavailable:
            return .unavailable("AI captions aren't available right now.")
        }
    }

    static func suggest(for postcard: Postcard) async throws -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let dateString = formatter.string(from: postcard.timestamp)

        let instructions = Instructions("""
        You write short, warm postcard captions. Captions must be at most one
        sentence, no more than 100 characters, and feel personal — like a note
        to a friend. Never use hashtags or emoji.
        """)

        let session = LanguageModelSession(instructions: instructions)
        let prompt = "Write a postcard caption from \(postcard.locationName), \(dateString)."
        let response = try await session.respond(to: prompt)
        return response.content
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
    }
}
