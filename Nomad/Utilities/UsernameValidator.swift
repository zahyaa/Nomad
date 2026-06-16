//
//  UsernameValidator.swift
//  Nomad
//
//  Client-side validation for the username chosen during onboarding.
//  This is not a security boundary — CloudKit must still enforce
//  uniqueness server-side — but it gives the user feedback before we
//  burn a network round-trip on a name we already know we'll reject.
//

import Foundation

enum UsernameValidator {
    enum ValidationError: LocalizedError, Equatable {
        case tooShort
        case tooLong
        case invalidCharacters
        case reserved
        case startsWithNumber
        case containsBlockedWord(String)

        var errorDescription: String? {
            switch self {
            case .tooShort:
                return "Pick a name with at least 3 characters."
            case .tooLong:
                return "Keep it under 20 characters."
            case .invalidCharacters:
                return "Only lowercase letters, numbers, and underscores."
            case .reserved:
                return "That name is reserved. Try another."
            case .startsWithNumber:
                return "Start with a letter, not a number."
            case .containsBlockedWord:
                return "That name isn't allowed. Try another."
            }
        }
    }

    /// System / role names a real user shouldn't claim.
    private static let reservedNames: Set<String> = [
        "admin", "administrator", "root", "system", "support", "help",
        "nomad", "official", "staff", "team", "everyone", "anonymous",
        "null", "undefined", "nil", "deleted", "removed",
        "me", "you", "self", "user", "guest", "test"
    ]

    /// Substrings we never want anywhere in a username. Conservative
    /// starter list — extend as you find new edge cases in beta.
    private static let blockedSubstrings: [String] = [
        "fuck", "shit", "bitch", "cunt", "nigger", "faggot", "retard",
        "rape", "kill", "nazi", "hitler"
    ]

    static func validate(_ candidate: String) -> ValidationError? {
        let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if trimmed.count < 3 { return .tooShort }
        if trimmed.count > 20 { return .tooLong }

        let allowed = CharacterSet.lowercaseLetters
            .union(.decimalDigits)
            .union(CharacterSet(charactersIn: "_"))
        if trimmed.rangeOfCharacter(from: allowed.inverted) != nil {
            return .invalidCharacters
        }

        if let first = trimmed.first, first.isNumber {
            return .startsWithNumber
        }

        if reservedNames.contains(trimmed) {
            return .reserved
        }

        for word in blockedSubstrings where trimmed.contains(word) {
            return .containsBlockedWord(word)
        }

        return nil
    }

    /// `true` if the username passes all client-side checks.
    static func isValid(_ candidate: String) -> Bool {
        validate(candidate) == nil
    }
}
