//
//  MessageValidator.swift
//  Nomad
//
//  TDD Implementation: Created to satisfy tests
//

import Foundation

/// Validation result for postcard messages
struct ValidationResult {
    let isValid: Bool
    let errors: [ValidationError]
    let trimmedMessage: String
    let characterCount: Int
    let containsURL: Bool
    
    enum ValidationError: Equatable {
        case tooLong
        case containsProfanity
        case invalidCharacters
    }
}

/// Validates postcard messages for length, content, and formatting
enum MessageValidator {
    
    // MARK: - Configuration
    
    private static let maxLength = 280
    
    // MARK: - Public API
    
    /// Validates a postcard message
    /// - Parameter message: The message to validate (can be nil)
    /// - Returns: ValidationResult with details about the message
    static func validate(_ message: String?) -> ValidationResult {
        // Handle nil or empty
        guard let message = message, !message.isEmpty else {
            return ValidationResult(
                isValid: true,
                errors: [],
                trimmedMessage: "",
                characterCount: 0,
                containsURL: false
            )
        }
        
        // Trim and normalize whitespace
        let trimmed = normalizeWhitespace(message)
        
        // Count characters (handles emoji correctly)
        let charCount = trimmed.count
        
        // Detect URLs
        let hasURL = containsURL(trimmed)
        
        // Validate length
        var errors: [ValidationResult.ValidationError] = []
        if charCount > maxLength {
            errors.append(.tooLong)
        }
        
        // Return result
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            trimmedMessage: trimmed,
            characterCount: charCount,
            containsURL: hasURL
        )
    }
    
    // MARK: - Private Helpers
    
    /// Normalizes whitespace in a string
    private static func normalizeWhitespace(_ text: String) -> String {
        // Trim leading/trailing whitespace
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Replace multiple spaces with single space
        let components = trimmed.components(separatedBy: .whitespaces)
        let filtered = components.filter { !$0.isEmpty }
        return filtered.joined(separator: " ")
    }
    
    /// Detects if text contains a URL
    private static func containsURL(_ text: String) -> Bool {
        // Use NSDataDetector to find URLs
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return false
        }
        
        let range = NSRange(text.startIndex..., in: text)
        let matches = detector.matches(in: text, options: [], range: range)
        
        return !matches.isEmpty
    }
}

// MARK: - Convenience Extensions

extension MessageValidator {
    
    /// Quick check if a message is valid
    static func isValid(_ message: String?) -> Bool {
        return validate(message).isValid
    }
    
    /// Get character count for display
    static func characterCount(_ message: String?) -> Int {
        return validate(message).characterCount
    }
    
    /// Check if message is too long
    static func isTooLong(_ message: String?) -> Bool {
        return validate(message).errors.contains(.tooLong)
    }
}
