//
//  MessageValidatorIntegrationExample.swift
//  Nomad
//
//  Example of using MessageValidator with TDD approach
//

import SwiftUI

/// Example integration of MessageValidator into PostcardComposerView
/// This shows how the TDD-created utility can be used in the real app
struct MessageValidatorUsageExample {
    
    // MARK: - Example 1: Real-time Character Count
    
    /// Show character count as user types
    func characterCountDisplay(for message: String) -> some View {
        let validation = MessageValidator.validate(message)
        let remaining = 280 - validation.characterCount
        
        return HStack {
            Text("\(validation.characterCount)/280")
                .font(.caption)
                .foregroundStyle(remaining < 0 ? .red : .secondary)
            
            if validation.errors.contains(.tooLong) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
            }
        }
    }
    
    // MARK: - Example 2: Validation Before Sending
    
    /// Validate message before allowing send
    func canSendPostcard(message: String?, recipient: String?) -> Bool {
        // Validate recipient exists
        guard let recipient = recipient, !recipient.isEmpty else {
            return false
        }
        
        // Validate message using our TDD utility
        let validation = MessageValidator.validate(message)
        
        // Can send if no errors (or empty message is OK for postcards)
        return validation.isValid
    }
    
    // MARK: - Example 3: Show Warning for URLs
    
    /// Display warning if message contains links
    func urlWarningView(for message: String) -> some View {
        let validation = MessageValidator.validate(message)
        
        return Group {
            if validation.containsURL {
                HStack(spacing: 8) {
                    Image(systemName: "link.circle.fill")
                        .foregroundStyle(.orange)
                    Text("Your message contains a link")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    // MARK: - Example 4: Auto-trim on Send
    
    /// Get cleaned message ready for sending
    func prepareMessageForSending(_ message: String?) -> String? {
        let validation = MessageValidator.validate(message)
        
        // Return nil if empty after trimming
        guard !validation.trimmedMessage.isEmpty else {
            return nil
        }
        
        // Return trimmed, normalized message
        return validation.trimmedMessage
    }
}

// MARK: - Integration in PostcardComposerView (Conceptual)

/*
 How to integrate MessageValidator into PostcardComposerView:

 1. Add validation state:
 
     @State private var messageValidation: ValidationResult?
 
 2. Update validation on text change:
 
     TextField("Message", text: $draftMessage)
         .onChange(of: draftMessage) { _, newValue in
             messageValidation = MessageValidator.validate(newValue)
         }
 
 3. Show character count:
 
     HStack {
         Text("Message")
         Spacer()
         if let validation = messageValidation {
             Text("\(validation.characterCount)/280")
                 .foregroundStyle(
                     validation.errors.contains(.tooLong) ? .red : .secondary
                 )
         }
     }
 
 4. Disable send button if invalid:
 
     Button("Send") {
         send()
     }
     .disabled(!(messageValidation?.isValid ?? true))
 
 5. Auto-trim before saving:
 
     func updateMessage() {
         let validation = MessageValidator.validate(draftMessage)
         postcard.message = validation.trimmedMessage.isEmpty ? nil : validation.trimmedMessage
     }
 
 6. Show URL warning:
 
     if messageValidation?.containsURL == true {
         Label("Message contains link", systemImage: "link")
             .font(.caption)
             .foregroundStyle(.orange)
     }
*/
