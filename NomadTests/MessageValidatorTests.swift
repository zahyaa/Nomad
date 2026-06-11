//
//  MessageValidatorTests.swift
//  NomadTests
//
//  TDD Example: Tests written BEFORE implementation
//

import Testing
@testable import Nomad

struct MessageValidatorTests {
    
    // MARK: - Length Validation Tests
    
    @Test func emptyMessage_isValid() {
        let result = MessageValidator.validate("")
        #expect(result.isValid == true)
        #expect(result.errors.isEmpty)
    }
    
    @Test func shortMessage_isValid() {
        let result = MessageValidator.validate("Hi!")
        #expect(result.isValid == true)
    }
    
    @Test func messageAtMaxLength_isValid() {
        let message = String(repeating: "a", count: 280) // Twitter-style limit
        let result = MessageValidator.validate(message)
        #expect(result.isValid == true)
    }
    
    @Test func messageExceedingMaxLength_isInvalid() {
        let message = String(repeating: "a", count: 281)
        let result = MessageValidator.validate(message)
        #expect(result.isValid == false)
        #expect(result.errors.contains(.tooLong))
    }
    
    // MARK: - Content Validation Tests
    
    @Test func messageWithEmojis_isValid() {
        let result = MessageValidator.validate("Hello 👋 from Paris! ✈️")
        #expect(result.isValid == true)
    }
    
    @Test func messageWithSpaces_trimmedCorrectly() {
        let result = MessageValidator.validate("   Hello   ")
        #expect(result.trimmedMessage == "Hello")
    }
    
    @Test func messageWithMultipleSpaces_normalizedCorrectly() {
        let result = MessageValidator.validate("Hello    world")
        #expect(result.trimmedMessage == "Hello world")
    }
    
    // MARK: - URL Detection Tests
    
    @Test func messageWithURL_isDetected() {
        let result = MessageValidator.validate("Check out https://example.com")
        #expect(result.containsURL == true)
    }
    
    @Test func messageWithoutURL_isNotDetected() {
        let result = MessageValidator.validate("No links here!")
        #expect(result.containsURL == false)
    }
    
    // MARK: - Profanity Filter Tests (optional feature)
    
    @Test func cleanMessage_passesFilter() {
        let result = MessageValidator.validate("What a beautiful sunset!")
        #expect(result.isValid == true)
    }
    
    // MARK: - Character Count Tests
    
    @Test func characterCount_isAccurate() {
        let result = MessageValidator.validate("Hello")
        #expect(result.characterCount == 5)
    }
    
    @Test func characterCountWithEmojis_countsCorrectly() {
        let result = MessageValidator.validate("Hi 👋") // emoji is multiple bytes
        #expect(result.characterCount == 4) // "Hi " + emoji
    }
    
    // MARK: - Edge Cases
    
    @Test func nilMessage_treatedAsEmpty() {
        let result = MessageValidator.validate(nil)
        #expect(result.isValid == true)
        #expect(result.characterCount == 0)
    }
    
    @Test func onlyWhitespace_trimmedToEmpty() {
        let result = MessageValidator.validate("   \n\t   ")
        #expect(result.trimmedMessage == "")
        #expect(result.characterCount == 0)
    }
}
